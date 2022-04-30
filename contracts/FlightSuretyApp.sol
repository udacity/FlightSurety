// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./BsfComptroller.sol";
import "./SuretyData.sol";

contract SuretyApp is Ownable {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

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

    IBsfComptroller private _comptroller;

    /**
    * @dev SuretyData accessor.
    */
    SuretyData private data;

    /**
    * @dev Operational status of the contract.
    */
    bool private _operational;
 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "_operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireOperational() 
    {
        require(_operational, "Contract is not currently operational.");  
        _;
    }

    modifier requireValidString(string memory value){
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
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
                                    address comptroller,
                                    address data
                                ) 
                                public 
    {
        require(comptroller != address(0), "'comptroller' cannot be equal to burn address.");
        _operational = true;
        _comptroller = IBsfComptroller(comptroller);
        _data = SuretyData(data);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function operational() 
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
        require(!_data.isAirlineRegistered(name), "The airline " + name + " is already registered.");
        uint256 fee = _data.fee(FeeType.Airline);
        require(msg.value - fee > 0, "Not enough value to cover the airline registration fee.");
        bool registered = _data.registerAirline(account, name);
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
        require(_data.isAirlineRegistered(airline), "The airline " + airline + " is not registered.");
        require(_data.isAirlineOperational(airline), "The airline " + airline + " is not operational.");

        address airlineAddress;
        string memory name;

        (airlineAddress,name,,,) = _data.getAirline(airline);

        //data.registerFlight(status, block.timestamp, );
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




}   
