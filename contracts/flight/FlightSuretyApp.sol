// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

// Base Contract
import "../BSF/BSFContract.sol";

// Airline Interface
import "../airline/IAirlineProvider.sol";

// Flight Interface
import "./IFlightProvider.sol";

// Fund Interface
import "../fund/IFundProvider.sol";

// Insurance Interface
import "../insurance/IInsuranceProvider.sol";

// Payout Interface
import "../payout/IPayoutProvider.sol";

// Token Interface
import "../BSF/BSF20/IBSF20.sol";

// NFT Interface
import "../BSF/BSF721/IBSF721.sol";

contract FlightSuretyApp is BSFContract {
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

    IAirlineProvider internal _airlines;
    IFlightProvider internal _flights;
    IInsuranceProvider internal _insurances;
    IPayoutProvider internal _payouts;

    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);
 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireFee(string key){
        bytes32 h = keccak256(key);
        if(h == keccak256(_bsf_airline)){
            require(msg.value >= _airlines.fee(), "");
        }

        if(h == keccak256(_bsf_flight)){
            require(msg.value >= _flights.fee(), "");
        }

        if(h == keccak256(_bsf_insurance)){
            require(msg.value >= _insurances.fee(), "");
        }

        if(h == keccak256(_bsf_payout)){
            require(msg.value >= _payouts.fee(), "");
        }
        _;
    }


    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    * @param comptroller {address}
    * @param backend {address} SuretyData Contract
    */
    constructor
            (
                address __comptroller,
                string __key
            ) 
            BSFContract(__comptroller, __key) 
    {
        require(__comptroller != address(0), "'__comptroller' cannot be equal to burn address.");
        _configure();
    }

    function _configAirlineProvider() internal {
        (bool enabled, address deployed) = _getContractAddress(_bsf_airline_data);
        if(enabled) {
            _airlines = IAirlineProvider(deployed);
        }
    }

    function _configFlightProvider() internal {
        (bool enabled, address deployed) = _getContractAddress(_bsf_flight_data);
        if(enabled) {
            _flights = IFlightProvider(deployed);
        }
    }

    function _configInsuranceProvider() internal {
        (bool enabled, address deployed) = _getContractAddress(_bsf_insurance_data);
        if(enabled) {
            _insurances = IInsuranceProvider(deployed);
        }
    }

    function _configPayoutProvider() internal {
        (bool enabled, address deployed) = _getContractAddress(_bsf_payout_data);
        if(enabled) {
            _payouts = IPayoutProvider(deployed);
        }
    }

    function _configure() internal {
        _configAirlineProvider();
        _configFlightProvider();
        _configInsuranceProvider();
        _configPayoutProvider();
    }

  
   /**
    * @dev Add an airline to the registration queue
    * @return { success:bool }
    * @return { votes:uint256 }
    */   
    function registerAirline
                            (
                                string name,
                                address account
                            )
                            external
                            pure
                            requireValidString(name)
                            requireValidAddress(account)
                            requireFee(_bsf_airline)
                            returns(bool success, uint256 votes)
    {
        require(!_airlines.isAirlineRegistered(name), string(abi.encodePacked("The airline ", name, " is already registered.")));
        success = false;//_data.registerAirline(account, name);
        votes = 0;//_data.getAirlineVotes(account, name);
    }

   /**
    * @dev Register a future flight for insuring.
    */  
    function registerFlight
                                (
                                    string airline,
                                    string flight,
                                    uint8 status,
                                    uint256 timestamp
                                )
                                external
                                pure
                                requireValidString(airline)
                                requireValidString(flight)
    {
        require(_airlines.isAirlineRegistered(airline), string(abi.encodePacked("The airline ", airline, " is not registered.")));
        require(_airlines.isAirlineOperational(airline), string(abi.encodePacked("The airline ", airline, " is not operational.")));


        bytes32 aid = _airlines.getAirlineId(airline);

        _flights.registerFlight(status, aid, flight, timestamp);
    }
    



    // Generate a request for oracles to fetch flight information
    function getFlightStatus
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
        // oracleResponses[key] = ResponseInfo({
        //                                         requester: msg.sender,
        //                                         isOpen: true
        //                                     });

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

    function getFlightId
                        (
                            string airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        requireOperational
                        returns(bytes32) 
    {
        bytes32 aid = _airlines.getAirlineId(airline);
        return _flights.getFlightId(aid, flight, timestamp);
    }

    /**
     * @return {array:int} of three non-duplicating integers from 0-9
     */
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8 random)
    {
        uint8 maxValue = 10;
        // Pseudo random number...the incrementing nonce adds variation
        random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);
        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }
    }
}   