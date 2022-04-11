// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./SuretyContract.sol";
import "./SuretyFund.sol";

contract FlightSuretyData is Ownable, SuretyFund, SuretyContract {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    /**
    * @dev Operational status of the contract.
    */
    bool private _operational = true;

    /**
    * @dev The fee types supported by the platform.
    */
    enum FeeType {
        Airline,
        Fund,
        Insurance
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    /// @notice Emitted when the owner of the surety contract changes.
    /// @param previousOwner The owner before the event was triggered.
    /// @param newOwner The owner after the event was triggered.
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Constructor
    * @dev The deploying account becomes contractOwner
    */
    constructor () public
    {
        _transferOwnership(msg.sender);
        _registerAirline(contractOwner, "Frontier Airlines");
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
    * @dev Get operating status of contract
    * @return A bool that is the current operating status
    */      
    function operational() external view returns(bool) {
        return operational;
    }

    /**
     * @dev Set operating status of contract
     */
    function setOperational(bool mode) external onlyOwner {
        _operational = model;
    }
    /**
    * @dev Gets the current fee for specified fee type.
    * @param {feeType:FeeType}
    * @return {_fee:uint256} The current fee for specified type.
    */
    function fee(FeeType feeType) external view returns(uint256){
        if(FeeType.Fund == feeType){
            return _feeFund;
        }
        if(FeeType.Airline == feeType){
            return _feeAirline;
        }
        if(FeeType.Insurance == feeType){
            return _feeInsurance;
        }
        return 0;
    }
    /**
    * @dev Sets the fee for a specified fee type.
    */
    function setFee(FeeType feeType, uint256 amount) external {
        require(amount >= 0, "Fee cannot be negative.");
        if(FeeType.Fund == feeType){
            _feeFund = amount;
        }
        if(FeeType.Airline == feeType){
            _feeAirline = amount;
        }
        if(FeeType.Insurance == feeType){
            _feeInsurance = amount;
        }
    }
    /**
    * @dev Sets contract operations on/off
    * @notice When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external onlyOwner {
        operational = mode;
    }
    /**
    * @dev Gets the key to identify a flight.
    */
    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }
    /**
    * @dev Gets the key to identify a fund.
    */
    function getFundKey(string memory name){
        return keccak256(abi.encodePacked(_bsf_fund, name));
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /********************************************************************************************/
    /*                                     START Airline FUNCTIONS                             */
    /********************************************************************************************/
    function _existsAirline(string memory name) private returns(bool){
        return airlines[keccak256(abi.encodePacked(_bsf_airline,name))].account != address(0);
    }
    /**
    * TODO: Document
    */
    function isAirlineRegistered(string memory name) external returns(bool) {
        require(bytes32(name).length > 0, "'name' must be a valid string.");
        return airlines[keccak256(abi.encodePacked(_bsf_airline,name))].registered;
    }
    /**
    * TODO: Document
    */
    function isAirlineOperational(string memory name) external returns(bool){
        require(bytes32(name).length > 0, "'name' must be a valid string.");
        return airlines[keccak256(abi.encodePacked(_bsf_airline,name))].isOperational;
    }

    function _getAirline(string memory name) private returns(address,string memory,bool,bool,uint256){
            Airline ret = airlines[keccak256(abi.encodePacked(_bsf_airline,name))];
            return (ret.account,ret.name,ret.registered,ret.operational,ret.vote);
    }
    /**
     * Get(s) an airline 'object' by name.
     */
    function getAirline(string memory name) 
        external 
        requireOperational 
        returns(address,string memory,bool,bool,uint256) {
            require(bytes32(name).length > 0, "'name' must be a valid string.");
            return _getAirline(name);
    }
    /**
    * @dev Registers an account as an airline.
    */
    function _registerAirline(address account, string memory name) private {
        bytes32 id = keccak256(abi.encodePacked(_bsf_airline, name));
        _airlines[id] = Airline({
            account: account,
            registered: true,
            isOperational: false,
            vote: block.timestamp + 2 days
        });
        emit AirlineRegistered(id, name);
    }
    /**
    * @dev Registers an airline vote.
    */
    function _registerAirlineVote(bytes32 id, bool choice) private {
        _airlineVotes[id].push(AirlineVote({account: msg.sender,choice:choice}));
        emit AirlineVoteRegistered(id, choice, msg.sender);
    }
   /**
    * @dev Add an airline to the registration queue
    * @dev Can only be called from FlightSuretyApp contract
    * @param { account:address }
    */   
    function registerAirline(address account, string memory name)
        external
        pure
        requireOperational
        returns (bool registered) {
            uint256 id = keccak256(abi.encodePacked(_bsf_airline,name));
            require(_airlines[id].registered == false, "Airline is already registered.");
            _registerAirline(account, name);
            require(_airlineVotes[id].length == 0, "Airline vote has already begun.");
            _registerAirlineVote(name);
            registered = _airlines[id].registered;
    }

    function registerAirlineVote(string memory name, bool choice)
        external
        pure
        requireOperational {
            uint256 id = keccak256(abi.encodePacked(_bsf_airline, name));
            require(block.timestamp - _airlines[id].vote > 0, "The voting period has expired.");
            _registerAirlineVote(id, choice);
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

    /**
    * @see {_registerFund:function}
    */
    function registerFund(string name, bool isPublic) external requireOperational {
        require(!existsFund(name), "A fund with this name already exists.");
        uint256 _fee = _calculateFee(FeeType.Fund, msg.value);
        uint256 amount = msg.value - _fee;
        require(amount > 0, "Appropriate fee not supplied.");
        _registerFund(msg.sender, name, amount ,isPublic);
    }

    /**
    * @dev Determines if a fund with the specified name exists.
    */
    function existsFund(string name) external returns(bool) {
        return _funds[getFundKey(name)].owner != address(0);
    }

    /********************************************************************************************/
    /*                                     START Insurance FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Buy insurance for a flight
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {}

    function _credit(bytes32 _contract, uint256 value) private {
        Insurance bond = _contracts[_contract];
        require(bond.payable, "Insurance contract must be in a 'payable' state.");
        //_payouts[bond.account]
        //payouts[insured] = payout;
    }

    /**
    * @dev Credit insured contracts.
    */
    function credit(address fund, address insured, uint256 value) external pure requireOperational {
        require((fund != address(0) && insured != address(0)), "Accounts must be valid address.");
        require(_funds[fund].name.length > 0, "The target fund does not exist.");
        require(_contracts[insured].passenger == insured, "Insure was not an insured passenger.");

    }

    function withdraw(address insured) external requireOperational returns(uint256){
        require(msg.sender == insured, "Only insured party may withdraw an authorized payout.");
        uint256 value = 0;
        return value;
    }

    /********************************************************************************************/
    /*                                     END Insurance FUNCTIONS                             */
    /********************************************************************************************/

    /********************************************************************************************/
    /*                                     BEGIN Flight FUNCTIONS                             */
    /********************************************************************************************/

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }

    function registerFlight(uint8 status, string airline, string flight) external requireOperational {
        require(_existAirline(airline), "");
        keccak256(abi.encodePacked(_bsf_airline,name));
    }

    function _registerFlight(uint8 status, address airline, string flight) {

    }

    /********************************************************************************************/
    /*                                     END Flight FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        //fund();
    }
}

