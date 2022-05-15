// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "./BsfComptroller.sol";

contract BsfToken is DetailedERC20 {

  IBsfComptroller _comptroller;

  event Mint(address indexed to, uint256 amount);

  modifier authorized() {
        require(_comptroller.access(_key, msg.sender), "BSF Contract access required.");
        _;
  }

  constructor(string name_, string symbol_, uint8 decimals_, address comptroller_) 
    DetailedERC20(name_, symbol_, decimals_) {
      _comptroller = IBsfComptroller(comptroller_);
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public authorized {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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
    external
    authorized
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
}
