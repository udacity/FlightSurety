pragma solidity ^0.4.25;

import "../node_modules/bsf-solidity/contracts/access/Ownable.sol";
import "../node_modules/bsf-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../node_modules/bsf-solidity/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract BSFSuretyToken is Ownable, ERC20Burnable, ERC20PresetMinterPauser {
    constructor() ERC20Burnable("BSF Surety Token", "BSFST") public {

    }
}
