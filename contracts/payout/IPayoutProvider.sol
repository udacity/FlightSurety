// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IPayoutProvider {
    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 fee_);
    /**
     * Set(s) the fee for a key.
     */
    function setFee(uint256 value_) external returns(bool r);
}