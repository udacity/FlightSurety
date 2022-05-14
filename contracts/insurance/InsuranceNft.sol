// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../BsfComptroller.sol";

contract InsuranceNft is ERC721Token, Ownable {

    IBsfComptroller _comptroller;
    string private _key = "bsf.insurance.nft";

    constructor(string __name, 
                string __symbol,
                address __comptroller) 
                ERC721(__name,__symbol) {
                    require(__comptroller != address(0), "'__comptroller' cannot be equal to burn address.");
                    _comptroller = IBsfComptroller(_comptroller);
    }

    modifier authorized() {
        require(_comptroller.access(_key, msg.sender), "BSF contract access required.");
        _;
    }

    function _getNextTokenId() {
        return allTokens[allTokens.length - 1].add(1);
    }

    function mint(string memory ) external authorized {
        _mint(msg.sender, _getNextTokenId());
    }
}