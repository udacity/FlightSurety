// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PayoutData {
    using SafeMath for uint256;

    /**
     * @dev Payouts accessor.
     */
    mapping(address => uint256) _payouts;

    /**
    * @dev Event for contract payout.
    */
    event Payout(address indexed account, uint256 value);
}