// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./BSF20/IBSF20.sol";

contract BSFContractSolo is Ownable {
    string internal _key;
    /**
    * @dev Operational status of the contract.
    */
    bool internal _operational;

    IBSF20 internal _token;

    event ComptrollerChanged(address newAddress, address deployer);

    constructor(string key_) {
        _operational = true;
        _key = key_;
    }
}