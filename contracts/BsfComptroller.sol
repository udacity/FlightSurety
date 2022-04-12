// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

interface IBsfComptroller {
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
    function existsContract(string memory key) returns (bool);
    /**
     * @dev Gets a 'AuthContract' object.
     * @param {string} The contract key.
     * @return {bytes32:id, bool:enabled, address:deployed} Contract struct.
     */
    function getContract(string memory key) returns (bytes32, bool, address);
    /**
     * @dev Gets the contract id
     * @param key {string} The contract key.
     */
    function getContractId(string memory key) returns (bytes32);
    /**
     * @dev Disables specified contract by key.
     * @param key {string} The contract key.
     */
    function disableContract(string memory key) returns (bool);
    /**
     * @dev Registers a contract.
     * @param key {string} The contract key.
     * @param deployed {address} The deployed contract address.
     */
    function registerContract(string memory key, address deployed) returns (bool);
    /**
     * @dev Updates a contract deployed address with the comptroller.
     * @param key {string} The contract key.
     * @param deployed {address} The deployed contract address.
     */
    function setContractDeployed(string memory key, address deployed) returns (bool);
}

contract BsfComptroller is Ownable, IBsfComptroller {

    string private _bsf_comptroller = "bsf.comptroller";

    struct AuthContract{
        bool enabled;
        address deployed;
    }

    mapping(uint256 => AuthContract) _authorized;

    event ContractAuthorized(address indexed deployed, bytes32 id, string key);
    event ContractDisabled(address indexed deployed, bytes32 id, string key);

    function _existsContract(bytes32 id) private returns (bool exists){
        exists = _authorized[id].deployed != address(0);
    }
    function existsContract(string memory key) external view returns(bool exists){
        return _existsContract(_getContractId(key));
    }

    function _getContract(string memory key) private view returns(bytes32 id, bool enabled, address deployed) {
        AuthContract c = _authorized[key];
        id = _getContractId(key);
        enabled = c.enabled;
        deployed = c.deployed;
    }
    function getContract(string memory key) external view returns (bytes32, string memory, bool, address) {
        return _getContract(key);
    }

    function _getContractId(string memory key) private returns (bytes32 id) {
        id = keccak256(abi.encodePacked(_bsf_contract, key));
    }
    function getContractId(string memory key) external view returns(bytes32 id){
        return _getContractId(deployed);
    }

    function _registerContract(bytes32 id, address deployed) private returns(bool) {
        _authorized[id] = AuthContract({
            enabled: true,
            deployed: deployed
        });
        return true;
    }
    function registerContract(string memory key, 
                              address deployed)
                              external
                              onlyOwner
        returns(bool ret){
            require(deployed != address(0), "'deployed' cannot be burn address.");
            uint256 id = _getContractId(key);
            require(!_existsContract(id), "'key' already registered, use update functionality.");
            if(_registerContract(id, deployed)){
                emit ContractAuthorized(deployed, id, key);
                return true;
            }
            return false;
    }

    function _setContractDeployed(bytes32 id, address deployed) private returns(bool) {
        AuthContract storage c = _authorized[id];
        c.deployed = deployed;
        return c.deployed == deployed;
    }
    function setContractDeployed(string memory key, address deployed) external returns(bool){
        uint256 id = _getContractId(key);
        require(_existsContract(id), "The contract specified by 'key' doesn't exist.");
        if(_setContractDeployed(id, deployed)){
            emit ContractDeployedChanged(deployed, id, key);
            return true;
        }
        return false;
    }
}