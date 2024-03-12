// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    FlightSuretyData_contrApp flightSuretyData_app;
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codes
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
    mapping(bytes32 => Flight) flights; // private
 
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

    modifier requireIsRegisteredAirline() 
    {
         // Modify to call data contract's status
        require(isAirlineRegistered(msg.sender), "Airline is not currently registered on the insurance");  
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
    constructor(address contractAdress) 
    {
        contractOwner = msg.sender;
        flightSuretyData_app = FlightSuretyData_contrApp(contractAdress);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) 
    {
        return flightSuretyData_app.isOperational();  // Modify to call data contract's status
    }

    function isAirlineRegistered(address airlineAdr) public view returns(bool) 
    {
        return flightSuretyData_app.isAirlineRegistered(airlineAdr);  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline(address airlineAdr, string calldata airlineName) external returns(bool success, uint256 votes)
    {
        return flightSuretyData_app.registerAirline(msg.sender, airlineAdr, airlineName);
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(string calldata flightName, uint8 statusCodeF, uint256 timestampFlght) external requireIsRegisteredAirline requireIsOperational returns(bool success)
    { //requireIsRegisteredAirline requireIsOperational
        // Flight memory newFlight = Flight({
        //     isRegistered: true,
        //     statusCode: statusCodeF,
        //     updatedTimestamp: timestampFlght,
        //     airline: msg.sender}); // each airline includes its own flights
            
        bytes32 flightNameBytes = bytes32(uint256(keccak256(abi.encodePacked(flightName))));
        // flights[flightNameBytes] = newFlight;

        Flight memory newFlight = flights[flightNameBytes];
        newFlight.isRegistered = true;
        newFlight.statusCode = statusCodeF;
        newFlight.updatedTimestamp = timestampFlght;
        newFlight.airline = msg.sender;
        flights[flightNameBytes] = newFlight;
        
        return true;
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus(bytes32 flight, uint256 timestamp, uint8 statusCode) internal
    {
        flights[flight].statusCode = statusCode;
        flights[flight].updatedTimestamp = timestamp;
    }

    function getFlightStatus(string calldata flight) external view returns(uint8){
        bytes32 flightBytes = bytes32(uint256(keccak256(abi.encodePacked(flight))));
        return flights[flightBytes].statusCode;
    }

    function isFlightRegistered(string calldata flightName) external view returns(bool){
        bytes32 flightNameBytes = bytes32(uint256(keccak256(abi.encodePacked(flightName))));
        return flights[flightNameBytes].isRegistered;
    }

    function getFlightAirline(string calldata flightName) external view returns(address){
        bytes32 flightNameBytes = bytes32(uint256(keccak256(abi.encodePacked(flightName))));
        return flights[flightNameBytes].airline;
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string calldata flight, uint256 timestamp) external
    {
        bytes32 flightBytes = bytes32(uint256(keccak256(abi.encodePacked(flight))));
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flightBytes, timestamp));
        // oracleResponses[key] = ResponseInfo({requester: msg.sender,
        //                                      isOpen: true
        //                                     });
        // ResponseInfo memory newResponseInfo = ResponseInfo({
        //     requester: msg.sender,
        //     isOpen: true,
        //     responses: new Response[](0)
        //     });
    
        // Add the new ResponseInfo to the oracleResponses mapping
        // oracleResponses[key] = newResponseInfo;
        ResponseInfo storage newResponseInfo = oracleResponses[key]; //https://ethereum.stackexchange.com/questions/117658/copying-of-type-struct-memory-memory-to-storage-not-yet-supported
        newResponseInfo.requester = msg.sender;
        newResponseInfo.isOpen = true;
        // newResponseInfo.responses = new Response[](0);
        oracleResponses[key] = newResponseInfo;

        emit OracleRequest(index, airline, flightBytes, timestamp);
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
    struct Response {
        address oracleAddress;
        uint8 statusCode;
    }
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        // mapping(uint8 => address[]) responses;
        Response[] responses;                           // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;
    
    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, bytes32 flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, bytes32 flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, bytes32 flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() view external returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    mapping(bytes32 => mapping(uint8 => uint256)) public responseCounts;

    function submitOracleResponse(uint8 index, address airline, string calldata flight, uint256 timestamp, uint8 statusCode) external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        bytes32 flightBytes = bytes32(uint256(keccak256(abi.encodePacked(flight))));
        bytes32 key = keccak256(abi.encodePacked(index, airline, flightBytes, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        // create oracle response
        // uint8 randomOracleResponse = uint8((getRandomIndex(msg.sender) + 1)/ 2)*10; // solidity floor numbers insteas of rounding, adding 1 prevent not to have number 50

        // ResponseInfo storage respOr = oracleResponses[key];
        // respOr.requester = oracleResponses[key].requester;
        // respOr.responses.push(Response(msg.sender, statusCode));
        // oracleResponses[key].responses[statusCode].push(msg.sender);
        // oracleResponses[key].responses[oracleResponses[key].responses.length + 1] = Response(msg.sender, statusCode);
        oracleResponses[key].responses.push(Response(msg.sender, statusCode));

        // Keep track of the number of responses for each status code
        responseCounts[key][statusCode]++;

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flightBytes, timestamp, statusCode);
        if (responseCounts[key][statusCode] >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flightBytes, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(flightBytes, timestamp, statusCode);
        }
    }

    function getResponseCounts(bytes32 key, uint8 statusCode) external view returns(uint256){
        return responseCounts[key][statusCode];
    }

    function getFlightKey(uint8 index, address airline, string calldata flight, uint256 timestamp) pure external returns(bytes32) 
    {
        bytes32 flightBytes = bytes32(uint256(keccak256(abi.encodePacked(flight))));
        return keccak256(abi.encodePacked(index, airline, flightBytes, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3] memory)
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
    function getRandomIndex(address account) internal returns (uint8)
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

interface FlightSuretyData_contrApp{
    function registerAirline(address airlineVoter, address airlineAdr, string calldata airlineName) external returns(bool success, uint256 votes);
    function isOperational() external view returns(bool);
    function isAirlineRegistered(address airlineAdr) external view returns(bool);
}