pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    uint8 private constant MINIMUM_AIRLINE_PARTICIPANT = 4;
    uint256 private constant MAX_INSURANCE_LIMIT = 1 ether; 
    uint256 private constant MIN_FUNDS = 10 ether;

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
        mapping(address => bool) votedFlag;
    }
    mapping(address => Airline) private airlines;
    uint private airlineCount;

    // Clients  Obj
    struct Clients
    {
        bool isInsured;
    }

    // Flights obj, track flights with their IDs
    struct Flights 
    {
        uint256 status;
        uint256 departure;
        uint256 price;
        mapping(address => Clients) passengers;
    }

    // map flights with its ID(bytes32)
    mapping(bytes32 => Flights) flights;

    


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

    modifier requireIsNotInsured(bytes32 flightID, address _address)
    {
      require(flights[flightID].passengers[_address].isInsured == false, "Address already has insurance for this flight");
      _;
    }
    
    modifier requireIsInsured(bytes32 flightID, address _address)
    {
      require(flights[flightID].passengers[_address].isInsured == true, "Address is not not (yet) insured!");
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

    function isAirline
                            (
                                address _airline
                            )
                            external
                            view
                            returns(bool)
    {
        return airlines[_airline].isMember;
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
                            requireIsOperational
                            requireIsAuthorized
                            requireIsNotYetMember(airlineAddress)
                            returns(bool)
    {
        // If we reached  minimum paticipant, we have to vote first to see if the new guy may join the club
        if(airlineCount >= MINIMUM_AIRLINE_PARTICIPANT)
            // number of votes must be at least half of total airline members
            require(voteBox[airlineAddress].mul(3) >= airlineCount, "Vote unsuccesful");

        airlines[airlineAddress] = Airline({isMember:true, airlineName:airlineName}); 
        airlineCount.add(1);
        return true;
    }

    function vote
                            (
                                address voter,
                                address candidate
                            ) 
                            external
                            requireIsOperational
                            requireIsAuthorized
    {
        require(airlines[voter].votedFlag[candidate] == false, "User already used their vote for this airline");

        airlines[voter].votedFlag[candidate] = true;
        voteBox[candidate] = voteBox[candidate].add(1);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                                bytes32 flightID
                            )
                            external
                            payable
                            requireIsOperational
                            requireIsNotInsured(flightID, msg.sender)
    {
        require(msg.sender == tx.origin, "contracts can't call this functions");
        require(msg.value > 0 , "Insufficient fund!");

        if(msg.value > MAX_INSURANCE_LIMIT)
        {
            msg.sender.transfer(MAX_INSURANCE_LIMIT);
        }
        else
        {
            msg.sender.transfer(msg.value);
        }
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                view
                                requireIsOperational
                                requireIsAuthorized
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
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
    {
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

