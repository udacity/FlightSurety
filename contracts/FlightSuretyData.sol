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
        bool isParticipationValid;
    }

    struct Passenger {
        address account;
        uint256 pricePaid;
    }

    mapping(address => Airline) airlines;
    mapping(address => Passenger) passengers;

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
        airlines[contractOwner] = Airline({account: contractOwner, isRegistered: true, isParticipationValid: true });
        airlineList.push(contractOwner);
    }

    event AirlineParticipationValidated(address account);
    event AirlineRegistered(address account);

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

    modifier isParticipationValid()
    {
        require(airlines[msg.sender].isParticipationValid == true, "To participate, you need to pay 10 ether");
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

    function setParticipationValid()
                                external
                                payable
    {
        require(airlines[msg.sender].isParticipationValid != true, "Payment of 10eth already made");
        require(msg.sender == tx.origin, "Contracts not allowed");
        uint256 fee = 10000000000000000000;
        require(msg.value >= fee, "Insufficient funds. Must have 10 Eth");

        msg.value.sub(fee);
        airlines[msg.sender].isParticipationValid = true;
        emit AirlineParticipationValidated(msg.sender);
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
                            isParticipationValid
                            returns(bool)
    {
        require(!airlines[account].isRegistered, "User is already registered.");
        if (airlineList.length <= 4) {
            // must be contract owner
            require(msg.sender == contractOwner, "Caller is not contract owner");
            // only existing airlines may register a new arline
            require(airlines[msg.sender].account == msg.sender, "Must be an existing registered airline to register new airlines");

            airlines[account] = Airline({account: account, isRegistered: true, isParticipationValid: false});
            return true;
        }
        // check if duplicate and if airline is registered
        bool isDuplicate = false;
        for (uint c = 0; c < multiCalls.length; c++) {
            require(airlines[multiCalls[c]].account == msg.sender, "Must be an existing registered airline to register new airlines");
            if(multiCalls[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Caller has already called this function");
        // check if half of registered airlines approves
        multiCalls.push(msg.sender);
        if(multiCalls.length >= uint256(airlineList.length) / 2) {
            airlines[account] = Airline({account: account, isRegistered: true, isParticipationValid: false});

            multiCalls = new address[](0);
        }
        emit AirlineRegistered(msg.sender);
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
        require(passengers[msg.sender].pricePaid < 1000000000000000000, "You cannot exceed 1 Eth");
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
    {
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
        fund();
    }


}