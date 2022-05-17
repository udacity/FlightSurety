// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

import "../BSFContract.sol";

contract BSF20 is IBSF20,
                  DetailedERC20, 
                  BurnableToken,
                  MintableToken, 
                  BSFContract {

  constructor(string name_, string symbol_, uint8 decimals_, address __comptroller, string __key) 
    BSFContract(__comptroller, __key)
    DetailedERC20(name_, symbol_, decimals_) {}

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    authorized
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
