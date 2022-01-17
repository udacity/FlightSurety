pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    /**
    * @dev Owner of the contract.
    */
    address private contractOwner;
    /**
    * @dev Operational status of the contract.
    */
    bool private operational = true;
    /**
    * @dev Current rate for registering and adding liquidity to a fund.
    */
    uint256 private feeFund = 0.01;
    /**
    * @dev Current registration rate for airlines.
    */
    uint256 private feeAirline = 1 ether;
    /**
    * @dev Current insurance rate.
    */
    uint256 private feeInsurance = 0.01;
    /**
    * @dev Airlines accessor.
    */
    mapping(address => Airline) airlines;
    /**
    * @dev Insurance Contracts accessor.
    */
    mapping(address => Insurance) contracts;
    /**
    * @dev Insurance Funds accessor.
    */
    mapping(address => Fund) funds;
    /**
    * @dev Voter
    */
    mapping(address => Voter) voters;
    /**
    * @dev Vote counts for Voters.
    */
    mapping(address => uint256) private votes;
    /**
    * @dev Authorized callers.
    */
    mapping(address => uint256) callers;
    /**
    * @dev Multi call addresses.
    */
    mapping(address => bool) multi;
    /**
    * @dev The fee types supported by the platform.
    */
    enum FeeType {
        Airline,
        Fund,
        Insurance
    }
    /**
    * @dev Defines a "registered" airline.
    */
    struct Airline {
        bool isOperational;
    }
    /**
    * @dev Defines an insurance contract.
    */
    struct Insurance {
        /**
        * @dev Insured account address.
        */
        address account;
        /**
        * @dev Insured value.
        */
        uint256 value;
        /**
        * @dev Fund for payout calculation & source.
        */
        bytes32 fund;
    }
    /**
    * @dev Defines an insurance fund.
    */
    struct Fund {
        /**
        * @dev The name of the insurance fund.
        */
        string name;
        /**
        * @dev Fund value.
        */
        uint256 amount;
        /**
        * @dev Fund insured payout multiplier.
        */
        uint256 payout;
    }
    /**
    * @dev Defines a liquidity provision.
    */
    struct Liquidity {
        /**
        * @dev The fund id.
        */
        address fund;
        /**
        * @dev Amount locked into liquidity.
        */
        uint256 amount;
        /**
        * @dev Locked yield rate.
        */
        uint256 rate;
        /**
        * @dev Current yield.
        */
        uint256 yield;
    }
    /**
    * @dev Defines a voter.
    */
    struct Voter {
        bool status;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Event for contract authorization.
    * @param { deployed:address }
    */
    event ContractAuthorized(address deployed);
    /**
    * @dev Event for contract de authorization.
    * @param { deployed:address }
    */
    event ContractDeAuthorized(address deployed);
    /**
    * @dev Event for airline registration.
    */
    event AirlineRegistered(address account);
    /**
    * @dev Event for airline status change, operational / non-operational.
    */
    event AirlineStatusChange(address account, bool operational);
    /**
    * @dev TODO: Document
    */
    event FundRegistered(address account, string name);
    event FundPayout(address insured, uint256 value, uint256 );
    /**
    * @dev Event for liquidity registration
    * @param { account:address } contributor
    * @param { fund:address } fund owner address
    * @param { rate:uint256 } yield rate
    */
    event LiquidityRegistered(address account, address fund, uint256 rate);
    /**
    * @dev Event for contract payout.
    */
    event Payout(address account, uint256 value);

    /**
    * @dev Constructor
    * @dev The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        _registerFund(contractOwner,"General Fund");
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
        require(msg.sender == contractOner, "Caller is not contract owwner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Calculates the fee for specified fee type.
    */
    function _calculateFee(FeeType fee, uint256 value) private {
        require(fee == FeeType.Airline || fee == FeeType.Fund || fee == FeeType.Insurance, "'fee' is an unsupported type.");
        if(fee == FeeType.Airline) {
            return value.sub(value.sub(feeAirline));
        }
        if(fee == FeeType.Fund) {
            return value.mul(feeFund);
        }
        if(fee == FeeType.Insurance) {
            return value.mul(feeInsurance);
        }
    }
    /**
    * @dev Sets the status of an 'account' as a multi-caller.
    * @dev Multi-call is mainly for airlines **
    */
    function _setMultiCall(address account, bool status) private {
        require(multi[account].status != status, "Account status already in this status.");
        multi[account] = status;
    }
    /**
    * @dev Get the status of a multi-caller.
    */
    function getMultiCallStatus(address account) external requireIsOperational returns(uint256) {
        return multi[account];
    }
    /**
    * @dev Get operating status of contract
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }
    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }
    /**
    * @dev TODO: Document
    */
    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /********************************************************************************************/
    /*                                     START Airline FUNCTIONS                             */
    /********************************************************************************************/
    /**
    * TODO: Document
    */
    function isAirlineRegistered(address account) external returns(bool) {
        require(account != address(0), "'account' must be a valid address.");
        return airlines[account] != null;
    }
    /**
    * TODO: Document
    */
    function isAirlineOperational(address account) external returns(bool){
        require(account != address(0), "'account' must be a valid address.");
        return airlines[account] != null && airlines[account].isOperational;
    }
    /**
    * @dev Registers an account as an airline.
    */
    function _registerAirline(address account) private requireIsOperational {
        airlines[account] = Airline({
            isOperational: true
        });
        _setMultiCall(account);
        emit AirlineRegistered(account);
    }
   /**
    * @dev Add an airline to the registration queue
    *     @dev Can only be called from FlightSuretyApp contract
    * @param { account:address }
    */   
    function registerAirline(address account) external pure {
        require(airlines[account] == null, "Airline is already registered.");

        _registerAirline(account);
    }

    /********************************************************************************************/
    /*                                     END Airline FUNCTIONS                                */
    /********************************************************************************************/

    /**
    * @dev Registers a fund.
    * @param Fund Owner.
    * @param Fund Name.
    * @param Fund Payout Rate.
    */
    function _registerFund(address account, string memory name, uint256 payout) private requireIsOperational {
        funds[account] = Fund({
            name: name,
            amount: msg.value,
            payout: payout
        });
        emit FundRegistered(account, name);
    }

    /********************************************************************************************/
    /*                                     START Insurance FUNCTIONS                             */
    /********************************************************************************************/

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
    * @dev Credit insured contracts.
    */
    function credit(address fund, address insured, uint256 value) external pure requireIsOperational {
        uint256 payout = contracts[airline].value.mul(1.5);

        require(contracts[airline].passenger == insured, "Insure was not an insured passenger.");
        require(payout == value, "Payout must be greater than insured value.");
        require((airline != address(0) && insured != address(0)), "Accounts must be valid address.");

        payouts[insured] = payout;
    }

    function withdraw(address insured) external requireIsOperational returns(uint256){
        require(msg.sender == insured, "Only insured party may withdraw an authorized payout.");
        uint256 value = payouts[insured];
        return value;
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
        funds[contractOwner].amount += msg.value;
    }
    /********************************************************************************************/
    /*                                     END Insurance FUNCTIONS                             */
    /********************************************************************************************/

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

