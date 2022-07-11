// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IBSFComptroller {
    /**
    * @dev Event for contract authorization.
    * @param deployed {address} The contract deployed address.
    * @param id {bytes32} The id of the authorization.
    * @param key {string} The key of the contract.
    */
    event ContractAuthorized(address indexed deployed, bytes32 id, string key);
    /**
    * @dev Event for contract authorization.
    * @param deployed {address} The contract deployed address.
    * @param id {bytes32} The id of the authorization.
    * @param key {string} The key of the contract.
    */
    event ContractDeployedChanged(address indexed deployed, bytes32 id, string key);
    /**
    * @dev Event for contract de authorization.
    * @param deployed {address} The contract deployed address.
    * @param id {bytes32} The id of the authorization.
    * @param key {string} The key of the contract.
    */
    event ContractDisabled(address indexed deployed, bytes32 id, string key);
    /**
     * @dev Determines if a contract exists.
     */
    function existsContract(string calldata) external view returns (bool);
    /**
     * @dev Gets a 'AuthContract' object.
     * @return {bytes32:id, bool:enabled, address:deployed} Contract struct.
     */
    function getContract(string calldata) external view returns (bytes32, bool, address);
    /**
     * @dev Gets the contract id
     */
    function getContractId(string calldata) external view returns (bytes32);
    /**
     * @dev Disables specified contract by key.
     */
    function disableContract(string calldata) external returns (bool);
    /**
     * @dev Registers a contract.
     * @param deployed {address} The deployed contract address.
     */
    function registerContract(string calldata, address deployed) external returns (bool);
    /**
     * @dev Updates a contract {deployed:address} with the comptroller.
     * @param deployed {address} The deployed contract address.
     */
    function setContractDeployed(string calldata, address deployed) external returns (bool);
    /**
     * @dev Checks access to {key:string} for {caller:address}
     */
    function access(string calldata, address caller) external view returns(bool hasAccess);
    /**
     * @dev Grants access to {key:string} for {grantee:address}
     */
    function grantAccess(string calldata, address grantee) external returns(bool);
    /**
     * @dev Revokes access to {key:string} for {revokee:address}
     */
    function revokeAccess(string calldata, address revokee) external returns(bool);
}