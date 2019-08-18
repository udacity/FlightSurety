pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

     struct Airline {
        address account;
        bool isRegistered;
        bool isAirline;
    }

    struct Passenger {
        address account;
        uint256 pricePaid;
        bool isFlightDelayed;
    }

    mapping(address => Airline) airlines;
    mapping(address => Passenger) passengers;

    uint256 private funds;

    address[] airlineList = new address[](0);
    address[] multiCalls = new address[](0);


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
        contractOwner = msg.sender;
        airlines[contractOwner] = Airline({account: contractOwner, isRegistered: true, isAirline: true });
        airlineList.push(contractOwner);
    }

    event AirlineParticipationValidated(address account);
    event AirlineRegistered(address account);
    event insuranceBought(address account);

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

    modifier isAirlineValid()
    {
        require(airlines[msg.sender].isAirline == true, "To participate, you need to pay 10 ether");
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

    function isAirline(address account) external returns(bool){
        if (airlines[msg.sender].isAirline == true) {
            return true;
        }
            return false;
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
                                address account
                            )
                            external
                            isAirlineValid
                            returns(bool)
    {
        require(airlines[msg.sender].account == msg.sender, "Must be an existing registered airline to register new airlines");
        require(!airlines[account].isRegistered, "User is already registered.");
        airlines[account] = Airline({account: account, isRegistered: true, isAirline: false});
        emit AirlineRegistered(account);
        return true;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                                uint256 amount
                            )
                            external
                            payable
    {
        require(msg.sender == tx.origin, "Contracts not allowed");
        require(amount < 1 ether, "You have exceeded maximum amount of insurance");
        require(passengers[msg.sender].pricePaid < 1 ether, "You cannot exceed 1 Eth");
        require(passengers[msg.sender].pricePaid.add(amount) < 1 ether, "You cannot exceed 1 Eth");

        passengers[msg.sender] = Passenger({
                                    account: msg.sender,
                                    pricePaid: passengers[msg.sender].pricePaid.add(amount),
                                    isFlightDelayed: false
                                });
        msg.value.sub(amount);
        emit insuranceBought(msg.sender);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
    {
        passengers[msg.sender].isFlightDelayed = true;

        // only credit those that are elegible. allegible are those with delayed flights.
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
    {
        require(msg.sender == tx.origin, "Contracts not allowed");
        require(passengers[msg.sender].account == msg.sender, "Must buy insurance before you request payout");
        // pay 1.5x times the price paid
        uint256 payout = passengers[msg.sender].pricePaid.mul(15).div(10);
        passengers[msg.sender].pricePaid = 0;

        msg.sender.transfer(payout);
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
        require(airlines[msg.sender].isAirline != true, "Payment of 10 eth already made");
        airlines[msg.sender].isAirline = true;
        emit AirlineParticipationValidated(msg.sender);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
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
        require(msg.data.length == 0, "msg.data not 0");
        fund();
    }


}