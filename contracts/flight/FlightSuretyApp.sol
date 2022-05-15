// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../BsfComptroller.sol";
import "../BsfContract.sol";
import "./FlightSuretyData.sol";

contract SuretyApp is BsfContract {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    string internal _bsf_surety_app = "bsf.surety.app";
    string internal _bsf_surety__data = "bsf.surety._data";
    string internal _bsf_contract = "bsf.contract";
    string internal _bsf_fund = "bsf.fund";
    string internal _bsf_airline = "bsf.airline";
    string internal _bsf_airline_vote = "bsf.airline.vote";
    string internal _bsf_flight = "bsf.flight";

    string private _bsf_airline_nft = "bsf.airline.nft";
    string private _bsf_insurance_nft = "bsf.insurance.nft";

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
    * @dev The fee types supported by the platform.
    */
    enum FeeType {
        Airline,
        Fund,
        Insurance
    }

    IBsfComptroller internal _comptroller;

    /**
    * @dev SuretyData accessor.
    */
    SuretyData internal _data;
 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireFee(FeeType feeType){
        uint256 fee = _data.fee(feeType);
        require(msg.value - fee > 0, "Insufficient value in transaction, please include required fee.");
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
                address comptroller,
                address backend
            ) 
            public 
    {
        require(comptroller != address(0), "'comptroller' cannot be equal to burn address.");
        _operational = true;
        _comptroller = IBsfComptroller(comptroller);
        _data = SuretyData(backend);
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
                            requireValidString(name)
                            requireValidAddress(account)
                            requireFee(FeeType.Airline)
                            returns(bool success, uint256 votes)
    {
        require(!_data.isAirlineRegistered(name), "The airline " + name + " is already registered.");
        success = _data.registerAirline(account, name);
        votes = _data.getAirlineVotes(account, name);
    }

   /**
    * @dev Register a future flight for insuring.
    */  
    function registerFlight
                                (
                                    address airline,
                                    string memory flight,
                                    uint8 status
                                )
                                external
                                pure
                                requireValidAddress(airline)
                                requireValidString(flight)
    {
        require(_data.isAirlineRegistered(airline), "The airline " + airline + " is not registered.");
        require(_data.isAirlineOperational(airline), "The airline " + airline + " is not operational.");

        address airlineAddress;
        string memory name;

        (airlineAddress,name,,,) = _data.getAirline(airline);

        //_data.registerFlight(status, block.timestamp, );
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

    function getFlightId
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        requireOperational
                        returns(bytes32) 
    {
        return _data.getFlightId(flight, airline, timestamp);
    }
}   
