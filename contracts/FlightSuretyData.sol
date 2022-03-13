pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    uint8 private constant MINIMUM_AIRLINE_PARTICIPANT = 4;
    uint256 public constant MAX_INSURANCE_LIMIT = 1 ether;
    // uint256 public constant MIN_FUNDS = 10 ether;
    uint256 public constant MIN_FUNDS = 0.1 ether;


    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    // contracts that could call this contract will be saved
    mapping(address => bool) private authorizedContracts;
    // save the amount of votes per airlineAddress
    mapping(address => uint256) private voteBox;

    // Airline Obj, map Airline to their addresses, track num of airlines
    struct Airline
    {
        string airlineName;
        bool isMember;
        uint256 fundAmounts;
        mapping(address => bool) votedFlag;
    }
    mapping(address => Airline) private airlines;
    uint256 private airlineCount;

    // Clients  Obj
    struct Clients
    {
        mapping (string => uint256) insurance;
        uint256 credit;
    }
    mapping(address => Clients) private passengers;
    address[] public passengersAddress;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
    {
        operational = true;
        airlineCount = 1;
        contractOwner = msg.sender;
        authorizedContracts[msg.sender] = true;

        //register first airline
        airlines[msg.sender] = Airline({airlineName : "Happy-Flight", isMember : true, fundAmounts: 0});
    }

    /********************************************************************************************/
    /*                                       HELPER FUNCTIONS                                   */
    /********************************************************************************************/
    // from: https://ethereum.stackexchange.com/a/58342/79209
    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
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

    modifier requireIsAuthorized()
    {
        require(authorizedContracts[msg.sender], string(abi.encodePacked("TRUE", " Contract msg.sender: ", addressToString(msg.sender)," init: ", addressToString(msg.sender), " is not authorized")));
        _;
    }

    modifier requireIsMember(address airlineAddress )
    {
        require(airlines[airlineAddress].isMember, "Airline is not a member!");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireIsNotYetMember(address airlineAddress )
    {
        require(airlines[airlineAddress].isMember == false, string(abi.encodePacked("Airline ", addressToString(airlineAddress), " is already a member!")));

        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireIsRegistered()
    {
        require(airlines[msg.sender].isMember, "Address is not registered!");
        _;
    }

    modifier requireIsFunded()
    {
        require(airlines[msg.sender].fundAmounts >= MIN_FUNDS, string(abi.encodePacked("Airline ", addressToString(msg.sender), "has not allocated enough fund!")));
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

    /********************************************************************************************/
    /*                                       GETTER  FUNCTIONS                                  */
    /********************************************************************************************/

    function getAirlineCounts()
                            public
                            view
                            returns(uint)
    {
        return airlineCount;
    }


    function isAirline
                            (
                                address airlineAddress
                            )
                            external
                            view
                            returns(bool)
    {
        return airlines[airlineAddress].isMember;
    }


    function authorizeCaller
                            (
                                address addressToAuthorize
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[addressToAuthorize] = true;
    }


    function checkIfAuthorized
                            (
                                address caller
                            )
                            external
                            view
                            requireContractOwner
                            returns(bool)
    {
        return authorizedContracts[caller];
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
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    function getCredit (address _address) public view returns (uint256)
    {
        return passengers[_address].credit;
    }

    function getInsurance (string flightID, address _address) public view returns (uint256)
    {
        return passengers[_address].insurance[flightID];
    }

    function getVotes (address airlineAddress) public view returns (uint256)
    {
        return voteBox[airlineAddress];
    }
   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline
                            (
                                address airlineAddress,
                                string airlineName
                            )
                            external
                            //contract must be operational
                            requireIsOperational
                            // caller must be authorized
                            requireIsAuthorized
                            // caller must already paid the fund
                            requireIsFunded
                            // airline must not already be a member
                            requireIsNotYetMember(airlineAddress)
                            returns(bool)
    {
        // If we reached  minimum participant, we have to vote first to see if the new guy may join the club
        if(airlineCount >= MINIMUM_AIRLINE_PARTICIPANT)
            // number of votes must be at least half of total airline members
            require((voteBox[airlineAddress]).mul(2) >= airlineCount, "Vote unsuccessful");

        airlines[airlineAddress] = Airline({ airlineName: airlineName, isMember: true, fundAmounts: 0});
        airlineCount++;
        return airlines[airlineAddress].isMember;
    }

    function registerFirstAirline
                            (
                                address airlineAddress,
                                string airlineName
                            )
                            external
                            requireIsOperational
                            requireIsNotYetMember(airlineAddress)
                            returns(bool)
    {
        airlines[airlineAddress] = Airline({ airlineName: airlineName, isMember: true, fundAmounts: 0});
        airlineCount++;
    }


    function vote
                            (
                                address candidate
                            )
                            external
                            requireIsOperational
                            requireIsRegistered
                            requireIsFunded
    {
        require(airlines[msg.sender].votedFlag[candidate] == false, "User already used their vote for this airline");
        airlines[msg.sender].votedFlag[candidate] = true;
        voteBox[candidate] = voteBox[candidate].add(1);
    }


   /**
    * @dev Buy insurance for a flight
    */
    function buy
                            (
                                string flightID
                            )
                            external
                            payable
                            requireIsOperational
                            returns (uint256)
    {
        require(msg.sender == tx.origin, "Contracts  are not allowed!");
        require(msg.value > 0, "Insufficient amount in your Wallet!");

        passengers[msg.sender] = Clients({credit : 0});
        passengersAddress.push(msg.sender);

        // CHECK & EFFECT
        uint256 curr_value = passengers[msg.sender].insurance[flightID];
        uint256 rest_value;
        if ((msg.value + curr_value) > MAX_INSURANCE_LIMIT)
            rest_value = MAX_INSURANCE_LIMIT.sub(curr_value);
        else
            rest_value = msg.value;

        //TRANSFER & UPDATE
        msg.sender.transfer(rest_value);
        passengers[msg.sender].insurance[flightID] += rest_value;

        return passengers[msg.sender].insurance[flightID];
    }

    /**
     *  @dev Credits payouts to insurers
    */
    function creditInsurees
                                (
                                  string flightID
                                )
                                external
                                requireIsOperational
                                requireIsAuthorized

    {
        // CHECK
        for(uint256 i = 0; i < passengersAddress.length; i++)
        {
            address _address = passengersAddress[i];
            // CHECK
            // get the current data

            uint256 currCredit = passengers[_address].credit;
            uint256 currInsurance = passengers[_address].insurance[flightID];

            // EFFECT
            passengers[_address].insurance[flightID] = 0;

            //TRANSFER
            passengers[_address].credit = currCredit + currInsurance + currInsurance.div(2);
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insurer
     *
    */
    function pay
                            (
                            )
                            external
                            payable
                            requireIsOperational
    {
        // CHECK & EFFECT
        require(msg.sender == tx.origin, "contracts are not allowed");
        require(passengers[msg.sender].credit > 0, "No credit available");
        require(address(this).balance >= credit, "contract does not have enough funds");

        // EFFECT
        uint256 credit = passengers[msg.sender].credit;
        passengers[msg.sender].credit = 0;

        //TRANSFER
        msg.sender.transfer(credit);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
                            requireIsOperational
    {
        uint256 currentFunds = airlines[msg.sender].fundAmounts;
        airlines[msg.sender].fundAmounts = currentFunds + msg.value;

        // authorize caller when it is funded
        authorizedContracts[msg.sender] = true;
    }


    function getFunds
                            (
                             address account
                            )
                            public
                            view
                            requireIsOperational
                            returns(uint256)
    {
        return airlines[account].fundAmounts;
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
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}
