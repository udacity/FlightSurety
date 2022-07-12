// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSFContractSolo.sol";

contract BSFComptroller is BSFContractSolo {

    string private _key = "bsf.comptroller";

    struct Contract{
        bool enabled;
        address deployed;
    }

    mapping(bytes32 => Contract) _contracts;
    mapping(bytes32 => bool) _access;

    event ContractAuthorized(address indexed deployed, bytes32 id, string key);
    event ContractDeployedChanged(address indexed deployed, bytes32 id, string key);
    event ContractDisabled(address indexed deployed, bytes32 id, string key);

    modifier exists(string key) {
        require(_existsContract(_getContractId(key)), "The contract specified by 'key' doesn't exist.");
        _;
    }

    modifier notExists(string key) {
        require(!_existsContract(_getContractId(key)), "The contract specified by 'key' already exists.");
        _;
    }

    constructor(string __key) 
        BSFContractSolo(__key){}

    function _existsContract(bytes32 id) internal returns (bool ex){
        Contract storage c = _contracts[id];
        ex = c.deployed != address(0);
        return ex;
    }
    function existsContract(string key) external view returns(bool){
        bytes32 id = _getContractId(key);
        return _existsContract(id);
    }

    function _getContract(bytes32 id_) 
             internal 
             view 
             returns(bytes32 id, bool enabled, address deployed) {
                Contract storage c = _contracts[id];
                id = id_;
                enabled = c.enabled;
                deployed = c.deployed;
    }
    function getContract(string key) 
             external 
             view 
             exists(key) 
             returns (bytes32, bool, address) {
                return _getContract(_getContractId(key));
    }

    function _getContractId(string memory key) internal view returns (bytes32 id) {
        id = keccak256(abi.encodePacked(_key, key));
    }

    function getContractId(string key) external view returns(bytes32 id){
        return _getContractId(key);
    }

    function _registerContract(bytes32 id,string key, address deployed) internal returns(bool) {
        Contract memory c = Contract(true,deployed);
        _contracts[id] = c;
        if(_existsContract(id)){
            emit ContractAuthorized(deployed, id, key);
            return true;
        }
        return false;
    }

    function registerContract(string key, 
                              address deployed)
                              external
                              onlyOwner
        returns(bool ret){
            require(deployed != address(0), "'deployed' cannot be burn address.");
            bytes32 id = _getContractId(key);
            ret = _registerContract(id, key, deployed);
            return ret;
    }

    function _setContractDeployed(bytes32 id,string key, address deployed) internal returns(bool) {
        Contract storage c = _contracts[id];
        c.deployed = deployed;
        emit ContractDeployedChanged(deployed, id, key);
        return true;
    }
    function setContractDeployed(string key, address deployed) external exists(key) returns(bool){
        bytes32 id = _getContractId(key);
        if(_setContractDeployed(id, key, deployed)){
            return true;
        }
        return false;
    }

    function access(string key, address caller) 
             external 
             view 
             exists(key) 
             returns(bool hasAccess){
                require(caller != address(0), "Caller cannot be BURN address.");
                hasAccess = _access[_getAccessId(key, caller)];
    }

    function _getAccessId(string memory key, address accessor) 
             internal 
             view 
             returns(bytes32) {
                return keccak256(abi.encodePacked(key,accessor));
    }

    function _grantAccess(string memory key, address grantee) internal returns(bool) {
        _access[_getAccessId(key, grantee)] = true;
        return true;
    }
    function grantAccess(string key, address grantee) 
             external 
             onlyOwner 
             exists(key) 
             returns(bool) {
                return _grantAccess(key, grantee);
    }

    function _revokeAccess(string memory key, address revokee) internal returns(bool) {
        _access[_getAccessId(key, revokee)] = false;
        return true;
    }
    function revokeAccess(string key, address revokee) 
             external 
             onlyOwner 
             exists(key) 
             returns(bool) {
                return _revokeAccess(key, revokee);
    }
}