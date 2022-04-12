pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp is Ownable {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    string private _bsf_contract = "bsf.contract";
    string private _bsf_fund = "bsf.fund";

    string private _bsf_airline = "bsf.airline";
    string private _bsf_airline_vote = "bsf.airline.vote";

    string private _bsf_flight = "bsf.flight";

    address private _comptrollerAddress;
    IBsfComptroller private _comptroller;

    /**
    * @dev Unknown Status
    */
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    /**
    * @dev On Time Status
    */
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    /**
    * @dev Late - Airline Status
    */
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    /**
    * @dev Late - Weather Status
    */
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    /**
    * @dev Late - Technical Status
    */
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    /**
    * @dev Late - Other Status
    */
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    /**
    * @dev Account used to deploy contract
    */
    address private contractOwner;

    /**
    * @dev The fee types supported by the platform.
    */
    enum FeeType {
        Airline,
        Fund,
        Insurance
    }
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    /**
    * @dev
    */
    FlightSuretyData private data;

    bool private operational;
 
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
        require(operational, "Contract is not currently operational.");  
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
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        registerAirline("Frontier Airlines", msg.sender);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return data.operational();  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    * @return { success:bool }
    * @return { votes:uint256 }
    */   
    function registerAirline
                            (
                                string memory name,
                                address account
                            )
                            external
                            pure
                            returns(bool success, uint256 votes)
    {
        require(!data.isAirlineRegistered(name), "The airline " + name + " is already registered.");
        uint256 fee = data.fee(FeeType.Airline);
        require(msg.value - fee > 0, "Not enough value to cover the airline registration fee.");
        bool registered = data.registerAirline(account, name);
    }


   /**
    * @dev Register a future flight for insuring.
    */  
    function registerFlight
                                (
                                    string memory airline,
                                    string memory flight,
                                    uint8 status
                                )
                                external
                                pure
    {
        require(data.isAirlineRegistered(airline), "The airline " + airline + " is not registered.");
        require(data.isAirlineOperational(airline), "The airline " + airline + " is not operational.");

        address airlineAddress;
        string memory name;
        bool registered;
        bool operational;
        uint256 vote;
        (airlineAddress,name,,,) = data.getAirline(airline);

        data.registerFlight(status, block.timestamp, );
    }
    
   /**
    * @dev Called after oracle has updated flight status
    */  
    function processFlightStatus
                                (
                                    string memory airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {

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

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;




    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    

 

   





}   
