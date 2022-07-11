// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../BSF/BSFContract.sol";

import "./IPayoutProvider.sol";

contract PayoutData is BSFContract, IPayoutProvider {
    using SafeMath for uint256;

    /**
    * @dev Current rate for processing a payout.
    */
    uint256 internal _fee = 0.01 ether;

    /**
     * @dev Payouts accessor.
     */
    mapping(address => uint256) _payouts;

    /**
    * @dev Event for contract payout.
    */
    event Payout(address indexed account, uint256 value);
    /**
     * @dev Event for contract payout claim.
     */
    event PayoutClaimed(address indexed account, uint256 value);

    constructor (address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {
    }

    function fee() external view returns(uint256 fee_){
        fee_ = _fee;
    }

    function setFee(uint256 value_) external authorized returns(bool r){
        _fee = value_;
        r = _fee == value_;
    }

    function _registerPayout(address account, uint256 value) internal {
        //_payouts[account] += value;
        emit Payout(account, value);
    }

    function _claimPayout(address account) internal returns(bool success) {
        // uint256 payout = _payouts[account];
        // _payouts[account] -= payout;
        // success = payable(account).call{value: payout}("");
        // if(success) {
        //     emit PayoutClaimed(account, payout);
        // } else {
        //     _payouts[account] += payout;
        // }
        success = false;
    }
}