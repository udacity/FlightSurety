pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract BSFSuretyToken is Ownable, StandardBurnableToken, MintableToken, PausableToken, DetailedERC20 {
    constructor() DetailedERC20("BSF Surety Token V1","BSFSV1",uint8(9)) public {

    }
}
