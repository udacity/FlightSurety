pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IFlightSuretyData.sol";

contract FlightSuretyData is ISuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    /**
    * @dev Operational status of the contract.
    */
    bool private _operational = true;
    /**
    * @dev Current rate for registering and adding liquidity to a fund.
    */
    uint256 private _feeFund = 0.01;
    /**
    * @dev Current registration rate for airlines.
    */
    uint256 private _feeAirline = 1 ether;
    /**
    * @dev Current insurance rate.
    */
    uint256 private _feeInsurance = 0.01;

    uint256 private _ratePayout = 1.0;
    uint256 private _rateContribution = 1.0;

    /**
    * @dev Airlines accessor.
    */
    mapping(address => Airline) _airlines;
    /**
    * @dev Insurance Contracts accessor.
    */
    mapping(address => Insurance) _contracts;
    /**
    * @dev Insurance Funds accessor.
    */
    mapping(address => SuretyFund) _funds;
    /**
    * @dev Airline Registration / De-Registration.
    */
    mapping(string => VoteRound) _rounds;
    /**
    * @dev Voter
    */
    mapping(address => Vote) _votes;
    /**
    * @dev Authorized contract addresses.
    */
    mapping(address => bool) _authorized;

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
        bytes32 fund;
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
    }
    /**
    * @dev Defines a surety fund.
    */
    struct SuretyFund {
        bytes32 id;
        address owner;
        string name;
        uint256 ratePayout;
        uint256 rateContribution;
        bool isPublic;
    }
    /**
    * @dev Defines a surety fund contribution.
    */
    struct SuretyFundContribution {
        address contributor;

    }
    struct VoteRound {
        string id;
        bool result;
        int256 deadline;
        address airline;
    }
    /**
    * @dev Defines a vote.
    */
    struct Vote {
        bool status;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    /// @notice Emitted when the owner of the surety contract changes.
    /// @param previousOwner The owner before the event was triggered.
    /// @param newOwner The owner after the event was triggered.
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    /**
    * @dev Event for contract authorization.
    * @param { deployed:address }
    */
    event ContractAuthorized(address indexed deployed);
    /**
    * @dev Event for contract de authorization.
    * @param { deployed:address }
    */
    event ContractDeAuthorized(address indexed deployed);
    /**
    * @dev Event for airline registration.
    */
    event AirlineRegistered(address indexed account);
    /**
    * @dev Event for airline status change, operational / non-operational.
    */
    event AirlineStatusChange(address indexed account, bool operational);
    /**
    * @dev Event for contract payout.
    */
    event Payout(address indexed account, uint256 value);

    /**
    * @dev Constructor
    * @dev The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        _transferOwnership(msg.sender);
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
    modifier requireOperational() {
        require(_operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

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
    function _authorize(address account, bool status) private {
        require(multi[account].status != status, "Account status already in this status.");
        multi[account] = status;
    }
    /**
    * @dev Get the status of an authorized contract.
    */
    function getAuthorization(address account) external requireOperational returns(uint256) {
        return multi[account];
    }
    /**
    * @dev Get operating status of contract
    * @return A bool that is the current operating status
    */      
    function operational() external view returns(bool) {
        return operational;
    }
    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external onlyOwner {
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
    function _registerAirline(address account) private requireOperational {
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
    * @param Amount to contribute.
    * @param Are fund contributions public.
    */
    function _registerFund(address account, string memory name, uint256 amount, bool isPublic) private {
        funds[account] = Fund({
            owner: account,
            name: name,
            amount: amount,
            ratePayout: _payout,
            rateContribution: _contribution,
            isPublic: isPublic
        });
        emit FundRegistered(account, name);
    }

    function registerFund(string memory name, bool isPublic) external requireOperational {
        uint256 fee = _calculateFee(FeeType.Fund, msg.value);
        uint256 amount = msg.value - fee;
        require(amount > 0, "Appropriate fee not supplied.");
        _registerFund(msg.sender, name, amount ,isPublic);
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

    function _credit(address fund, address insured, uint256 value) private {
        uint256 payout = funds[insured].value.mul(_);
        payouts[insured] = payout;
    }

    /**
    * @dev Credit insured contracts.
    */
    function credit(address fund, address insured, uint256 value) external pure requireOperational {
        require((fund != address(0) && insured != address(0)), "Accounts must be valid address.");
        require(funds[fund].name.length > 0, "The target fund does not exist.");
        require(contracts[insured].passenger == insured, "Insure was not an insured passenger.");
    }

    function withdraw(address insured) external requireOperational returns(uint256){
        require(msg.sender == insured, "Only insured party may withdraw an authorized payout.");
        uint256 value = payouts[insured];
        return value;
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

