// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract BSFComptroller is Ownable {

    string private _bsf_comptroller = "bsf.comptroller";

    struct AuthContract{
        bool enabled;
        address deployed;
    }

    mapping(uint256 => AuthContract) _authorized;
    mapping(bytes32 => bool) _access;

    event ContractAuthorized(address indexed deployed, bytes32 id, string key);
    event ContractDeployedChanged(address indexed deployed, bytes32 id, string key);
    event ContractDisabled(address indexed deployed, bytes32 id, string key);

    function _existsContract(bytes32 id) internal returns (bool exists){
        exists = _authorized[id].deployed != address(0);
    }
    function existsContract(string key) external view returns(bool exists){
        return _existsContract(_getContractId(key));
    }

    function _getContract(string memory key) internal view returns(bytes32 id, bool enabled, address deployed) {
        AuthContract c = _authorized[key];
        id = _getContractId(key);
        enabled = c.enabled;
        deployed = c.deployed;
    }
    function getContract(string key) external view returns (bytes32, bool, address) {
        return _getContract(key);
    }

    function _getContractId(string memory key) internal view returns (bytes32 id) {
        id = keccak256(abi.encodePacked(_bsf_comptroller, key));
    }
    function getContractId(string key) external view returns(bytes32 id){
        return _getContractId(key);
    }

    function _registerContract(bytes32 id, address deployed) internal returns(bool) {
        _authorized[id] = AuthContract({
            enabled: true,
            deployed: deployed
        });
        return true;
    }
    function registerContract(string key, 
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

    function _setContractDeployed(bytes32 id, address deployed) internal returns(bool) {
        AuthContract storage c = _authorized[id];
        c.deployed = deployed;
        return c.deployed == deployed;
    }
    function setContractDeployed(string key, address deployed) external returns(bool){
        uint256 id = _getContractId(key);
        require(_existsContract(id), "The contract specified by 'key' doesn't exist.");
        if(_setContractDeployed(id, deployed)){
            emit ContractDeployedChanged(deployed, id, key);
            return true;
        }
        return false;
    }

    function access(string key, address caller) external view returns(bool hasAccess){
        require(_existsContract(_getContractId(key)), "");
        require(caller != address(0), "");
        hasAccess = _access[_getAccessId(key, caller)];
    }

    function _getAccessId(string memory key, address accessor) internal {
        return keccak256(abi.encodePacked(key,accessor));
    }

    function _grantAccess(string memory key, address grantee) internal returns(bool) {
        _access[_getAccessId(key, grantee)] = true;
        return true;
    }
    function grantAccess(string key, address grantee) external onlyOwner returns(bool) {
        require(_existsContract(_getContractId(key)), "");
        return _grantAccess(key, grantee);
    }

    function _revokeAccess(string memory key, address revokee) internal returns(bool) {
        _access[_getAccessId(key, revokee)] = false;
        return true;
    }
    function revokeAccess(string key, address revokee) external onlyOwner returns(bool) {
        require(_existsContract(_getContractId(key)), "");
        return _revokeAccess(key, revokee);
    }
}