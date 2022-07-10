// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSF/BSFContract.sol";

import "../utils/IProvider.sol";
import "../utils/IFeeProvider.sol";

import "./IFundProvider.sol";

contract FundData is BSFContract, IProvider, IFeeProvider, IFundProvider {
    using SafeMath for uint256;

    /**
    * @dev Current rate for registering and adding liquidity to a fund.
    */
    uint256 internal _fee = uint256(0.01);

    /**
    * @dev Defines a surety fund.
    */
    struct SuretyFund {
        address owner;
        string name;
        uint256 payout;
        uint256 contribution;
        bool pub;
    }
    
    /**
    * @dev Defines a surety fund contribution.
    */
    struct SuretyFundContribution {
        address contributor;
        uint256 rate;
        uint256 amount;
        uint256 timestamp;
        uint256 mature;
    }

    /**
    * @dev Insurance Funds accessor.
    */
    mapping(bytes32 => SuretyFund) _funds;
    mapping(address => uint256) _fundCount;

    /**
    * @dev Surety fund contributions
    */
    mapping(bytes32 => SuretyFundContribution) _contributions;
    mapping(address => uint256) _contributionCount;

    /**
    * @dev Event for surety fund registration.
    */
    event FundRegistered(bytes32 id, string name, address indexed account);

    /**
    * @dev Event for surety fund contribution.
    */
    event FundContribution(bytes32 id, uint256 amount, address indexed account);

    /**
    * @dev Event for surety fund contribution withdrawal
    */
    event FundContributionWithdrawal(bytes32 id, uint256 amount, address indexed account);

    constructor (address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {
    }

    function _existsFund(string memory name) internal view returns(bool) {
        return _funds[_getFundId(name)].owner != address(0);
    }

    /**
    * @dev Determines if a fund with the specified name exists.
    */
    function existsFund(string name) external view returns(bool){
        return _existsFund(name);
    }

    function _getFundCount(address owner) private returns(uint256 count){
        return _fundCount[owner];
    }

    /** 
     * @dev Gets a fund count for owner.
     */
    function getFundCount(address owner) external returns(uint256 count){
        return _getFundCount(owner);
    }

    function _getFundFee(uint256 value) private view returns(uint256 fee){
        fee = value.mul(_fee);
    }

    /**
     * @dev Calculates the current fund fee, with specified seed value.
     */
    function getFundFee(uint256 value) external view returns(uint256 fee){
        fee = _getFundFee(value);
    }

    function _getFundId(string name) private returns(bytes32 id){
        id = keccak256(abi.encodePacked(_bsf_insurance_fund, name));
    }

    /**
     * @dev Gets a fund id by owner / count.
     */
    function getFundId(string name) external returns(bytes32 id){
        id = _getFundId(name);
    }

    /**
     * @dev Gets the next fund id for a specified owner
     */
    function getNextFundId(string name) external returns(bytes32 id){
        id = _getFundId(name);
    }

    /**
    * @dev Registers a fund.
    * @param account {address} Fund Owner.
    * @param name {string} Fund Name.
    * @param amount {uint256} Amount to contribute.
    * @param pub {bool}Are fund contributions public.

    */
    function _registerFund(address account, 
                           string memory name,
                           bool pub,
                           uint256 payout,
                           uint256 contribution) 
                           private returns (bool) {
        bytes32 id = _getFundId(name);
        _funds[id] = SuretyFund({
            owner: account,
            name: name,
            payout: payout,
            pub: pub,
            contribution: contribution
        });
        emit FundRegistered(id, name, account);
    }

    /**
    * @see {_registerFund:function}
    */
    function registerFund(string name, bool pub, uint256 payout, uint256 contribution) external requireOperational {
        require(!_existsFund(name), "A fund with this name already exists.");
        _registerFund(msg.sender, name, pub, payout, contribution);
    }
}
