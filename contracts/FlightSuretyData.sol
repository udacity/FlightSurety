pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => uint256) private walletBalance;
    address[] private airlines;
    address[] private activeAirlines;   //Only active after 10 ether funded
    mapping (address=>bool) isActiveAirline;
    mapping (address=>address[]) airlineVotes;  //Need minimum 4 votes

    //Insurance Data variables
    struct Insurance {
        bytes32 id;   //Unique Identifier for Insurance
        bool isPaid; 
        address owner;
        uint256 amount;  //Using SafeMath
    } 
    mapping (bytes32=>Insurance) insuranceDetails;
    mapping (bytes32=>address[]) passengersEnsured;

    
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event airlineRegistered(address airlineAddress);
    event airlineFunded(address airlineAddress);
    event insurancePurchased(address airline,string flight, uint256 timestamp, address passenger, uint256 amount, bytes32 id);    //Should I send ID in event?
    event insuranceClaimed(address airline, string flight, uint256 timestamp, address passenger, uint256 amount, bytes32 id);
    event amountWithdrawn(address senderAddress, uint amount);


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor 
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        airlines.push(msg.sender);

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

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        require(mode != operational, "New mode should be different from current mode");
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
    function registerAirline
                            (   
                                address _airlineAddress
                            )
                            external
    {
        airlines.push(_airlineAddress);
        isActiveAirline[_airlineAddress] = false;
        emit airlineRegistered(_airlineAddress);
    }

    /**
     * @dev Vote for an airline
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function addAirlineVotes(address _newAirline, address _senderAddress) external requireIsOperational returns(address[]) {
        airlineVotes[_newAirline].push(_senderAddress);
    }

    /**
     * @dev Get the list of airline votes
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function getAirlineVotes(address _airlineAddress) external view requireIsOperational returns(address[]) {
        return airlineVotes[_airlineAddress];
    }

    /**
     * @dev check if the airline has voted
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function isAirlineVoted(address _newAirline, address _senderAddress) external view requireIsOperational returns (bool){
        bool isAlreadyVoted = false;
        for (uint256 i=0; i<airlineVotes[_newAirline].length; i.add(1)){  //is it worth using safemath?
            if(airlineVotes[_newAirline][i] == _senderAddress){
                isAlreadyVoted = true;
            }
        }
        return isAlreadyVoted;
    }

    /**
     * @dev check if the airline has already been registered
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function isAirlineRegistered(address _newAirline) external view requireIsOperational returns(bool) {
        bool isRegistered = false;
        for(uint256 i = 0; i < airlines.length; i++) {
            if(airlines[i] == _newAirline) {
                isRegistered = true;
            }
        }
        return isRegistered;
    }

    /**
     * @dev Get the list of registered airlines
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function getRegisteredAirlines() external view requireIsOperational returns(address[]) {
        return airlines;
    }


    /**
     * @dev Activate an airline
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function activateAirline(address _airlineAddress) external payable requireIsOperational {
        isActiveAirline[_airlineAddress] = true;
        activeAirlines.push(_airlineAddress);
        fund(_airlineAddress);
        emit airlineFunded(_airlineAddress);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (    
                            address _airline,
                            string _flight,
                            uint256 _timestamp,
                            address _passenger,
                            uint256 _insuranceAmount
                            )
                            external
                            payable
                            requireIsOperational
    {
        bytes32 flightKey = getFlightKey(_airline, _flight, _timestamp);
        bytes32 insuranceId = keccak256(abi.encodePacked(flightKey, _passenger));
        insuranceDetails[insuranceId] = Insurance({
            id: insuranceId,
            isPaid: false,
            owner: _passenger,
            amount: _insuranceAmount
        });
        passengersEnsured[flightKey].push(_passenger);
        fund(_airline);
        emit insurancePurchased(_airline, _flight,  _timestamp,  _passenger, _insuranceAmount,  insuranceId);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address _airline,
                                    string _flight,
                                    uint256 _timestamp,
                                    address _airlineAddress,
                                    address _passenger
                                )
                                external
                                requireIsOperational
    {
        bytes32 flightKey = getFlightKey(_airline, _flight, _timestamp);
        bytes32 insuranceId = keccak256(abi.encodePacked(flightKey, _passenger));
        require(insuranceDetails[insuranceId].id==insuranceId,"No such insurance Exists");
        require(insuranceDetails[insuranceId].isPaid==false,"Already claimed this amount");
        uint256 currentAirlineBalance = walletBalance[_airlineAddress];
        uint256 amountCreditedToPassenger = insuranceDetails[insuranceId].amount.mul(15).div(10);
        require(currentAirlineBalance >= amountCreditedToPassenger, "Airline Doesn't have enough funds. Please check later.");
        insuranceDetails[insuranceId].isPaid = true;
        walletBalance[_airlineAddress] = currentAirlineBalance.sub(amountCreditedToPassenger);
        walletBalance[_passenger] = walletBalance[_passenger].add(amountCreditedToPassenger);
        emit insuranceClaimed(_airline,_flight,_timestamp,_passenger,amountCreditedToPassenger,insuranceId);

    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address _insureeAddress
                            )
                            external
                            payable
    {
        require(walletBalance[_insureeAddress] > 0, "There is no balance available in your wallet");
        uint256 withdrawAmount = walletBalance[_insureeAddress];
        walletBalance[_insureeAddress] = 0;
        //Should it be msg.sender here???
        _insureeAddress.transfer(withdrawAmount);
        emit amountWithdrawn(_insureeAddress, withdrawAmount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address _address
                            )
                            public
                            payable
    {
    walletBalance[_address] = walletBalance[_address].add(msg.value);

    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }
    /**
     * @dev Check if the airline is funded/activated
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function isAirlineActivated(address airlineAddress) external view requireIsOperational returns(bool) {
        return isActiveAirline[airlineAddress];
    }
     /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund(msg.sender);
    }

}

