pragma solidity ^0.4.25;

import "../node_modules/bsf-solidity/contracts/token/ERC20/IERC20.sol";
import "../node_modules/bsf-solidity/contracts/access/IAccessControlEnumerable.sol";

interface IBSFSuretyToken is IERC20, IAccessControlEnumerable {

}