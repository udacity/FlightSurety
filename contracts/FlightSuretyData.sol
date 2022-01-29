pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    uint8 private constant MINIMUM_AIRLINE_PARTICIPANT = 4;
    uint256 public constant MAX_INSURANCE_LIMIT = 1 ether;
    uint256 public constant MIN_FUNDS = 10 ether;
    // uint256 public constant MIN_FUNDS = 0.1 ether;


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
    mapping(uint => Airline) private airlines2;
    bool testtest = false;
    uint256 private airlineCount;

    // Clients  Obj
    struct Clients
    {
        bool isInsured;
        uint256 insurance;
        uint256 credit;
    }

    // Flights obj, track flights with their IDs
    struct Flights
    {
        uint256 status;
        uint256 departure;
        uint256 price;
        mapping(address => Clients) passengers;
        // since we can't iterate through maps, we have to keep track
        // of number of addresses separately
        address[100] passengersAddress;
        uint256 idxPassengers;
    }

    // map flights with its ID(string)
    mapping(string => Flights) flights;




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
       require(authorizedContracts[msg.sender], "Contract is not authorized");
        _;
    }

    modifier requireIsMember(address airlineAddress )
    {
        require(airlines[airlineAddress].isMember, "Airline is not a member!");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireIsNotYetMember(address airlineAddress )
    {
        require(!airlines[airlineAddress].isMember, "Airline is already a member!");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireIsNotInsured(string flightID, address _address)
    {
      require(flights[flightID].passengers[_address].isInsured == false, "Address already has insurance for this flight");
      _;
    }

    modifier requireIsInsured(string flightID, address _address)
    {
      require(flights[flightID].passengers[_address].isInsured == true, "Address is not not (yet) insured!");
      _;
    }

    modifier requireIsRegistered()
    {
        require(airlines[msg.sender].isMember, "Address is not registered!");
        _;
    }

    modifier requireIsFunded()
    {
        require(airlines[msg.sender].fundAmounts >= MIN_FUNDS);
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
    function getCredit (string flightID, address passenger ) public view returns (uint256)
    {
        return flights[flightID].passengers[passenger].credit;
    }

    function getInsurance (string flightID, address passenger ) public view returns (uint256)
    {
        return flights[flightID].passengers[passenger].insurance;
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

    function vote
                            (
                                address candidate
                            )
                            external
                            requireIsOperational
                            requireIsRegistered
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
                            requireIsNotInsured(flightID, msg.sender)
                            returns (uint256)
    {
        require(msg.sender == tx.origin, "Contracts  are not allowed!");
        require(msg.value > 0, "Insufficient amount in your Wallet!");

        flights[flightID].passengers[msg.sender] = Clients({isInsured : true, insurance : 0, credit : 0});

        flights[flightID].passengersAddress[flights[flightID].idxPassengers] = msg.sender;
        flights[flightID].idxPassengers++;

        // CHECK & EFFECT
        if (msg.value > MAX_INSURANCE_LIMIT)
        {
            //TRANSFER & UPDATE
            msg.sender.transfer(MAX_INSURANCE_LIMIT);
            flights[flightID].passengers[msg.sender].insurance = MAX_INSURANCE_LIMIT;
        }
        else
        {
            uint256 value = msg.value;
            //TRANSFER & UPDATE
            address(this).transfer(value);
            flights[flightID].passengers[msg.sender].insurance = value;
        }
        return flights[flightID].passengers[msg.sender].insurance;
    }

    /**
     *  @dev Credits payouts to insurers
    */
    function creditInsurees
                                (
                                  string flightID,
                                  address passenger
                                )
                                external
                                requireIsOperational
                                requireIsAuthorized

    {
        // CHECK
        require(flights[flightID].idxPassengers > 0, "There is no passengers registered");
        for(uint256 i = 0; i < flights[flightID].idxPassengers; i++)
        {
            // CHECK
            // get the current data
            uint256 currCredit = flights[flightID].passengers[passenger].credit;
            uint256 currInsurance = flights[flightID].passengers[passenger].insurance;

            // EFFECT
            flights[flightID].passengers[passenger].insurance = 0;

            //TRANSFER
            flights[flightID].passengers[passenger].credit = currCredit + currInsurance + currInsurance.div(2);
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insurer
     *
    */
    function pay
                            (
                             string flightID
                            )
                            external
                            payable
                            requireIsOperational
                            requireIsInsured(flightID, msg.sender)
    {
        // CHECK & EFFECT
        require(msg.sender == tx.origin, "contracts are not allowed");
        require(flights[flightID].passengers[msg.sender].credit > 0, "No credit available");
        require(address(this).balance > credit, "contract does not have enough funds");

        // EFFECT
        uint256 credit = flights[flightID].passengers[msg.sender].credit;
        flights[flightID].passengers[msg.sender].credit = 0;

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
        airlines[msg.sender].fundAmounts = currentFunds.add(msg.value);

        // authorize caller when it is funded
        authorizedContracts[msg.sender] = true;
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
