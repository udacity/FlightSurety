// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../BsfComptroller.sol";
import "../BsfContract.sol";

contract FlightNft is ERC721Token, BsfContract {

    struct TokenData {
      bytes32 id;
      string seat;
      string zone;
    }

    mapping(uint256 => TokenData) private _data;

    constructor(string __name, 
                string __symbol,
                address __comptroller) 
                BSFContract(__comptroller)
                ERC721(__name,__symbol) {}

    function _getNextTokenId() {
        return allTokens[allTokens.length - 1].add(1);
    }

    function mint(bytes32 id, string seat, string zone) 
             external 
             authorized(_bsf_flight_nft) {
        uint256 next = _getNextTokenId();
        _mint(msg.sender, next);
        _data[next] = TokenData({id:id,seat:seat,zone:zone});
    }
}
