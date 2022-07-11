// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IInsuranceProvider {
    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 fee_);
    /**
     * Set(s) the fee for a key.
     */
    function setFee(string calldata) external returns(bool r);
}