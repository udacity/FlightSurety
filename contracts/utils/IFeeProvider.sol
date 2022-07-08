// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IFeeProvider {
    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 f);

    function setFee() external returns(bool r);
}