// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IProvider {
    /**
     * Get(s) the comptroller for the provider.
     */
    function comptroller() external view returns(address comptroller_);
    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 fee_);
    /**
     * Get(s) the id based upon specified key
     */
    function getId(string calldata) external view returns(bytes32 id_);
    /**
     * Get(s) the contracts key.
     */
    function key() external view returns(bytes32 id_);
}