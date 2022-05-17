// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../BSF/BSFContract.sol";

contract PayoutData is BSFContract {
    using SafeMath for uint256;

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

    function _registerPayout(address account, uint256 value) internal {
        _payouts[account] += value;
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
        return false;
    }
}