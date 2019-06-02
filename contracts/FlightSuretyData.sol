pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => bool) private registeredAirlines; //map of airlines that are registered with the dapp
    address[] airlines; // all the airlines registered - easy to fetch this way if needed
    mapping(address => bool) private authorizedCallerContracts; //map of app contract addresses which are authorized to call the functions of this app
    mapping(address => uint) private airlineFunds; // funds related to an airline
    mapping(bytes32 => address[]) private flightPassengersInsured; // passengers insured for a flight
    mapping(address => mapping(bytes32 => uint)) private passengerFlightInsurance; // amount of insurance for a flight by a passenger
    mapping(bytes32 => mapping(address => uint)) private passengerInsurancePayout; // amount to be paid to passengers for the insurance
    mapping(address => uint) private passengerAmountBalance; // balance to be paid to passenger

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address airline)
    public
    {
        contractOwner = msg.sender;
        registeredAirlines[airline] = true;
        airlines.push(airline);
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
    * @dev Modifier to check whether the caller contract is authorized
    */
    modifier requireIsCallerContractAuthorized() {
        require(authorizedCallerContracts[msg.sender] == true, "Contract not authorized to call the function");
        _;
    }

    /**
    * @dev check whether airline is registered
    */
    modifier requireIsAirlineRegistered(address airline) {
        require(isAirlineRegistered(airline), "Airline not registered");
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
    * @dev function for app contract to check that is the airline registered
    */
    function isAirlineRegistered(address airline)
    public
    view
    returns(bool)
    {
        return registeredAirlines[airline];
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool mode)
    external
    requireContractOwner
    {
        operational = mode;
    }

    /**
    * @dev Sets contract address authorized to call the functions
    */
    function authorizeContract(address contractAdress)
    external
    requireContractOwner
    {
        authorizedCallerContracts[contractAddress] = true;
    }

    /**
    * @dev Removes contract from authorized list
    */
    function deAuthorizeContract(address contractAdress)
    external
    requireContractOwner
    {
        delete authorizedCallerContracts[contractAddress];
    }

    /**
    * @dev check whether the passenger is insured for the flight
    */
    function isPassengerInsured(address airline, string flight, uint256 timestamp, address passenger)
    external
    view
    returns(bool)
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        return passengerFlightInsurance[passenger][airline] > 0;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(address airline)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    returns(bool)
    {
        require(airline != address(0), "Airline address is not valid");
        require(!isAirlineRegistered(airline), "Airline is already registered");

        registeredAirlines[airline] = true;
        airlines.push(airline);
        return true;
    }

    /**
    * @dev get all the airlines
    */
    function getAllAirlines()
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    view
    returns(address[])
    {
        return airlines;
    }

    /**
    * @dev add funds for an airline
    */
    function fundAirline(address airline, uint amount)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    requireIsAirlineRegistered(airline)
    {
        airlineFunds[airline] = airlineFunds[airline] + amount;
    }

    /**
    * @dev get the funds for an airline
    */
    function getAirlineFunds(address airline)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    requireIsAirlineRegistered(airline)
    returns(uint)
    {
        return airlineFunds[airline];
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy(address airline, string flight, uint256 timestamp, address passenger, uint amount)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    requireIsAirlineRegistered(airline)
    payable
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        flightPassengerInsured[flightKey].push(passenger);
        passengerFlightInsurance[passenger][flightKey] = amount;
        passengerInsurancePayout[flightKey][passenger] = 0;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(address airline, string flight, uint256 timestamp, uint insuranceMultiple,
                            uint insuranceDivisor)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        address[] storage insuredPassengers = flightPassengerInsured[flightKey];
        for(uint8 i = 0; i < insuredPassengers.length; i++) {
            address passenger = insuredPassengers[i];
            uint256 amountToBePaid;
            uint amount = passengerFlightInsurance[passenger][flightKey];
            uint paidAmount = passengerInsurancePayout[flightKey][passenger];
            // pay only if nothing has been paid
            if(paidAmount == 0) {
                amountToBePaid = amount.mul(insuranceFactor).div(insuranceDivisor);
                passengerInsurancePayout[flightKey][passenger] = amountToBePaid;
                passengerAmountBalance[passenger] = passengerAmountBalance[passenger] + amountToBePaid;
            }
        }
    }

    /**
    * @dev Get amount balance for passenger
    */
    function getPassengerBalance(address passenger)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    view
    returns(uint)
    {
        return passengerAmountBalance[passenger];
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address passenger, uint amount)
    external
    requireIsOperational
    requireIsCallerContractAuthorized
    returns(uint)
    {
        passengerAmountBalance[passenger] = passengerAmountBalance[passenger] - amount;
        passenger.transfer(amount);
        return passengerAmountBalance[passenger];
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund()
    public
    payable
    {}

    function getFlightKey(address airline, string memory flight, uint256 timestamp)
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
    function() external payable
    {
        fund();
    }


}

