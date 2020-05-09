pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedContracts;

    FlightSuretyData private flightSuretyData;

    enum AirlineState {
        Registered,
        Participating
    }

    mapping (address => AirlineState) private airlines;
    mapping (address => uint) private fund; // airline funding so far, helps to convert Registered airline to Participating airline



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    // Airline Registed
    event Registered(address airlineAddress);


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
        airlines[contractOwner] = AirlineState.Registered;
        emit Registered(contractOwner);
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

    /**
     * Modifier that requires the "Caller" account is authorized
     */
    modifier onlyAuthorizedContract()
    {
        require(authorizedContracts[msg.sender] == true, "Caller is not authorized");
        _;
    }

    /**
     * Modifier that requires airline is registred
     */
    modifier onlyRegistredAirline(address _airline)
    {
        require(airlines[_airline] == AirlineState.Registered, "Airline is not registred");
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
        operational = mode;
    }

    /**
     * @dev authorize caller contract FlightSuretyApp
     */
    function authorizeCaller(address contractAddress) external requireContractOwner
    {
        authorizedContracts[contractAddress] = true;
    }

    /**
     * @dev remove authorized caller contract FlightSuretyApp
     */
    function removeAuthorizedCaller(address contractAddress) external requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /**
     * @dev check if caller is Authorized
     */
    function isCallerAuthorized(address contractAddress) public view requireContractOwner returns (bool)
    {
        return authorizedContracts[contractAddress];
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
                                address _airline
                            )
                            external
                            requireIsOperational
    {
        airlines[contractOwner] = AirlineState.Registered;
        emit Registered(contractOwner);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
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
                            requireIsOperational
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

