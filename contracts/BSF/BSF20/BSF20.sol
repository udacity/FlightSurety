// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

import "../BSFContract.sol";

//DetailedERC20
//DetailedERC20(name_, symbol_, decimals_)
contract BSF20 is IBSF20, BSFContract, BurnableToken, MintableToken {
  constructor(string name_, string symbol_, uint8 decimals_, address __comptroller, string __key) 
  BSFContract(__comptroller,__key){}
}
