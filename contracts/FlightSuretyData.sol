// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
pragma solidity 0.8.0;

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint8 MAX_INSURANCE = 1;

    struct AirlineProfile {
        bool isRegistered;
        bytes32 airline_name;
        bool hasGivenFund;
    }

    mapping(address => AirlineProfile) officialAirline;   // Mapping for storing registered Airline

    mapping(address => uint32) voteForAirline; // number of vote a wannabe registered airline received
    mapping(address => mapping(address => bool)) HasVotedForSaidAirline; // check if voter has already voted to include airline or not - cannot vote twice
    uint256 private numVoterMin = 1;
    uint256 private numAirlineReg = 0; // will be set to 1 during initialisation, when contract owner register first airline
    uint256 private counter = 1;

    mapping(address => bool) authorizedApp;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    // the address that want to register an airline must be a registered airline itself, to give fund to the contract you need to be a registered airline
    modifier requireRegisteredAirline()
    {
        require(officialAirline[msg.sender].isRegistered, "Caller is not a registered airline");
        _;
    }

    modifier reEntrancyGuard() 
    {
        counter = counter.add(1);
        uint256 guard = counter;
        _;
        require(guard == counter, "Not allowed");
    }

    modifier appIsAuthorized() 
    {
        require(authorizedApp[msg.sender] == true, "Caller is not allowed");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    function authorizeCaller(address app_flightSurety) requireContractOwner public returns(bool isAuthorized){
        authorizedApp[app_flightSurety] = true;
        return true;
    }

    function unAuthorizeCaller(address app_flightSurety) requireContractOwner public returns(bool isUnAuthorized){
        authorizedApp[app_flightSurety] = false;
        return true;
    }

    function hasGivenFund(address airlineQuery) public view returns(bool){
        return officialAirline[airlineQuery].hasGivenFund;
    }

    function isAppAuthorized(address app_flightSurety) public view returns(bool isAuthorized){
        return authorizedApp[app_flightSurety];
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner 
    {
        require(mode != operational, "New mode must be different from existing mode");
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */ 

    // check max insurance price
    function getMaxInsurancePrice() external view returns(uint8){
        return MAX_INSURANCE;
    }
    
    // modify number of voters needed to register an airline
    function setNumberOfVoters(uint256 numbOfAirline) private{
        if (SafeMath.mod(numbOfAirline,2) != 0){
            numVoterMin = SafeMath.add(SafeMath.div(numbOfAirline,2),1); // if odd number of airline, round up (if 5 airlines are rgistered, need 3 to vote an airline in)
        } else{
            numVoterMin = SafeMath.div(numbOfAirline,2); // if even number of airline, half of them is needed to allow extra airline
        }
    }

    // check if an airline is registered
    function isAirlineRegistered(address account) public view returns(bool){
            require(account != address(0), "'account' must be a valid address.");
            return officialAirline[account].isRegistered;
    }

    function registerAirline(address airlineVoter, address airlineAdr, string calldata airlineName) external requireIsOperational appIsAuthorized returns(bool success, uint256 votes) 
    {
        require(!officialAirline[airlineAdr].isRegistered, "Applicant airline is already registered."); // if the airline is already registered there is no point re-adding it
        require(officialAirline[airlineVoter].hasGivenFund || airlineVoter == contractOwner, "Voter airline has not yet completed application. It cannot participate to registering.");
        require(!HasVotedForSaidAirline[airlineVoter][airlineAdr], 'Voter already voted to include applicant airline');
        // only need one vote at first
        voteForAirline[airlineAdr] = voteForAirline[airlineAdr] + 1;
        if(numAirlineReg >= 4){
            setNumberOfVoters(numAirlineReg); // this updates numVoterMin, if there are 4 registered airlines or more, need 50% of airlines to vote the new airline in
        }
        if(voteForAirline[airlineAdr] >= numVoterMin){
            bytes32 airlineName_bytes = bytes32(uint256(keccak256(abi.encodePacked(airlineName))));
            officialAirline[airlineAdr] = AirlineProfile({isRegistered: true, airline_name: airlineName_bytes, hasGivenFund: false});
            HasVotedForSaidAirline[airlineVoter][airlineAdr] = true;
            success = true;
            numAirlineReg += 1;
        } else {
            success = false;
        }
        return (success, voteForAirline[airlineAdr]);
    }

    function getNumberRegisteredAirline() external view returns(uint256){
        return numAirlineReg;
    }

    mapping(string => mapping(address => uint256)) insurees; // save how much a customer paid for an flight insurance
    mapping(string => uint256) insureeCorresNum; // count how many insuree in a flight
    mapping(uint256 => address) corresTable; // each customer address for a insured flight as an associated number


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(address airlineAdr, string calldata flight) requireIsOperational external payable returns(bool success)
    {
        require(officialAirline[airlineAdr].isRegistered, "Airline is not registered as part of the insurance.");
        require(officialAirline[airlineAdr].hasGivenFund, "Airline has not yet completed application. You cannot get insured with it yet.");
        require(insurees[flight][msg.sender] == 0, 'You already purchased insurance for this flight.');
        require(msg.value <= MAX_INSURANCE  * 1 ether, 'You cannot purchase insurance for more than 1 ether.');
        payable(airlineAdr).transfer(msg.value);
        insurees[flight][msg.sender] = msg.value;
        insureeCorresNum[flight] = insureeCorresNum[flight] + 1;
        corresTable[insureeCorresNum[flight]] = msg.sender;

        return true;
    }

    function IsCustomerInsured(string calldata flight) external view returns(bool success){
        return insurees[flight][msg.sender] > 0;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    mapping(address => uint) credit_insuree;
    function creditInsurees(string calldata flight) external requireIsOperational requireRegisteredAirline returns(bool success)
    {
        require(insureeCorresNum[flight] > 0, 'No customer purchased insurance on this flight.'); // fail fast : if no passenger took insurance for the flight, dismiss
        uint256 iCred = 1;
        uint256 creditAmount;
        for (iCred = 1; iCred <= insureeCorresNum[flight] ; iCred++) { // insureeCorresNum provides number of insured people for every flights
            creditAmount = insurees[flight][corresTable[iCred]]; // get amount insuree bought insurance for, find address of insuree via the variable corresTable
            insurees[flight][corresTable[iCred]] = 0;
            credit_insuree[corresTable[iCred]] = SafeMath.add(credit_insuree[corresTable[iCred]],SafeMath.div(SafeMath.mul(creditAmount,3),2)); // credit 1.5 x the insurance price
        }
        return true;
    }

    function insureeHasCredit() external view returns(bool){
        if(credit_insuree[msg.sender] > 0){
            return true;
        }else{
            return false;
        }
    }

    function displayInsureeCreditAmount() external view returns(uint){
        return credit_insuree[msg.sender];
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
 function pay() requireIsOperational reEntrancyGuard external payable returns(bool success, uint256 fundPayout)
    {
        require(credit_insuree[msg.sender] > 0, 'There is no fund to withdraw.');
        fundPayout = credit_insuree[msg.sender];
        credit_insuree[msg.sender] = 0;
        payable(msg.sender).transfer(fundPayout);

        return (true, fundPayout);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public payable requireIsOperational requireRegisteredAirline returns(bool success)
    {
        require(msg.value >= 10 ether,'At least 10 ether are needed to fund the membership.');
        officialAirline[msg.sender].hasGivenFund = true;
        
        return true;
    }

    function getContractBalance() view public requireContractOwner returns (uint)
    {
        return address(this).balance;    
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    receive() external payable 
    {
        fund();
    }


}