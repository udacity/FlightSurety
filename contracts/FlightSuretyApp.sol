pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    // collection of flights
    mapping(bytes32 => Flight) private flights;

    // data contract address
    FlightSuretyData private flightSuretyDataContract;

    // number of polls airline has received for registration
    mapping(address => uint8) airlinePollCountMapping;

    // mapping to hold the collection of airlines voted for an airline
    mapping(address => mapping(address => bool)) airlinesVotedForAirlineMapping;

    // number of votes for an airline mapping
    mapping(address => uint256) votesPerAirline;

    uint private MIN_AIRLINES_FUND_REQUIRED = 10 ether;
    uint private MAX_INSURANCE_ALLOWED = 1 ether;
    uint8 private MIN_AIRLINES_FOR_CONSENSUS = 4;
    uint private numberOfAirlinesRegistered = 1;




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
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");
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

    /**
    * @dev check whether the airline is registered
    */
    modifier requireIsAirlineRegistered(address airline)
    {
      require(isAirlineRegistered(airline), "Airline is not registered");
      _;
    }

    /**
    * @dev check whether the airline has deposited sufficient funds
    */
    modifier requireCallerAirlineHasSufficientFunds()
    {
        uint funds = flightSuretyDataContract.getAirlineFunds(msg.sender);
        require(funds >= MIN_AIRLINES_FUND_REQUIRED, "Insufficient funds deposited by airline");
        _;
    }

    /**
    * @dev check whether the timestamp is in future
    */
    modifier requireIsTimestampValid(uint timestamp)
    {
        uint blockTime = block.timestamp;
        require(blockTime <= timestamp, "Timestamp should be in future");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address flightSuretyDataContractAddress)
                                public
    {
        contractOwner = msg.sender;
        flightSuretyDataContract = FlightSuretyData(flightSuretyDataContractAddress);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev function to check whether the contract is operational
    */
    function isOperational()
    public
    view
    returns(bool)
    {
        return flightSuretyDataContract.isOperational();  // Modify to call data contract's status
    }

    /**
    * @dev function to check whether the airline is registered
    */
    function isAirlineRegistered(address airline)
    public
    view
    returns(bool)
    {
        return flightSuretyDataContract.isAirlineRegistered(airline);
    }

    /**
    * @dev function to check whether an airline has voted for an airline
    */
    function hasAirlineVotedForRegisteringAirline(address airline, address registeringAirline)
    internal
    view
    returns(bool)
    {
        return airlinesVotedForAirlineMapping[registeringAirline][airline];
    }

   /**
    * @dev function to check whether an airline has voted for an airline
    */
    function setAirlineVotedForRegisteringAirline(address airline, address registeringAirline)
    internal
    {
        airlinesVotedForAirlineMapping[registeringAirline][airline] = true;
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline(address airline)
    external
    requireIsOperational
    requireIsAirlineRegistered(msg.sender)
    requireCallerAirlineHasSufficientFunds
    returns(bool success, uint256 votes)
    {
        require(airline != address(0), "Airline address is not valid");
        require(!isAirlineRegistered(airline), "Airline is already registered");
        votes = 0;
        success = false;
        if(numberOfAirlinesRegistered < MIN_AIRLINES_FOR_CONSENSUS) {
            success = flightSuretyDataContract.registerAirline(airline);
        } else {
            // check for duplicate call for vote
            if(!hasAirlineVotedForRegisteringAirline(msg.sender, airline)) {
                setAirlineVotedForRegisteringAirline(msg.sender, airline);
                // increment the number of votes an airline has received
                votesPerAirline[airline] = votesPerAirline[airline] + 1;
                if(votesPerAirline[airline] >= numberOfAirlinesRegistered.div(2)) {
                    success = flightSuretyDataContract.registerAirline(airline);
                    votes = votesPerAirline[airline];
                }
            }

        }
        if(success) {
            numberOfAirlinesRegistered++;
        }

        return (success, votes);
    }

    /**
    * @dev add funds from an airline
    */
    function fundAirline()
    public
    requireIsOperational
    requireIsAirlineRegistered(msg.sender)
    payable
    {
        // transfer fund to data contract
        address(flightSuretyDataContract).transfer(msg.value);
        flightSuretyDataContract.fundAirline(msg.sender, msg.value);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight(address airline, string flight, uint timestamp)
    external
    requireIsOperational
    requireIsAirlineRegistered(airline)
    requireIsTimestampValid(timestamp)
    require
    payable
    {
        require(msg.value <= MAX_INSURANCE_ALLOWED, "Insurance fee should be less than or equal to 1 ether");
        require(!isPassengerInsured(airline, flight, timestamp, msg.sender), "Passenger already insured for this flight");
        address(flightSuretyDataContract).transfer(msg.value);
        flightSuretyDataContract.buy(airline, flight, timestamp, msg.sender, msg.value);
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode)
    internal
    requireIsOperational
    {
        if(statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightSuretyDataContract.creditInsurees(airline, flight, timestamp, 150, 100);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    /**
    * @dev get all the airlines registered
    */
    function getAllAirlines()
    public
    requireIsOperational
    view
    returns(address[])
    {
        return flightSuretyDataContract.getAllAirlines();
    }

    /**
    * @dev get the passenger balance remaining
    */
    function getPassengerBalance()
    public
    requireIsOperational
    view
    returns(uint)
    {
        return flightSuretyDataContract.getPassengerBalance(msg.sender);
    }

    /**
    * @dev withdraw funds
    */
    function withdrawFunds(uint amount)
    public
    requireIsOperational
    returns(uint)
    {
        require(flightSuretyDataContract.getPassengerBalance(msg.sender) >= amount, "Balance is less than the requested amount");
        return flightSuretyDataContract.pay(msg.sender, amount);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

contract FlightSuretyData {
    function isOperational() public view returns(bool);
    function isAirlineRegistered(address airline) public view returns(bool);
    function registerAirline(address airline) external returns(bool);
    function getAllAirlines() external view returns(address[]);
    function fundAirline(address airline, uint amount) external;
    function getAirlineFunds(address airline) external returns(uint);
    function buy(address airline, string flight, uint256 timestamp, address passenger, uint amount) external payable;
    function creditInsurees(address airline, string flight, uint256 timestamp, uint insuranceMultiple, uint insuranceDivisor) external;
    function getPassengerBalance(address passenger) external view returns(uint);
    function pay(address passenger, uint amount) external returns(uint);
    function isPassengerInsured(address airline, string flight, uint256 timestamp, address passenger) external view returns(bool);
}
