pragma solidity ^0.4.25;

interface ISuretyData {
    /// @notice Emitted when the owner of the surety contract changes.
    /// @param previousOwner The owner before the event was triggered.
    /// @param newOwner The owner after the event was triggered.
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    // @return The owner of the contract.
    function owner() external view returns (address);
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * NOTE: Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;
}
