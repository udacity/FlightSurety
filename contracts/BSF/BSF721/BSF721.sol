// SPDX-License-Identifier: MIT
//pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

import "../../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../../../node_modules/openzeppelin-solidity/contracts/AutoIncrementing.sol";
import "../BSFComptroller/BSFComptroller.sol";
import "../BSFContract.sol";

contract BSF721 is ERC721Token,BSFContract {
    using SafeMath for uint256;
    using AutoIncrementing for AutoIncrementing.Counter;

    IBSFComptroller internal _comptroller;
    AutoIncrementing.Counter internal _id;
    bool internal _mint_lock = false;
    string internal _key;

    struct TokenData {
      bytes32 id;
      string data;
    }

    mapping(uint256 => TokenData) internal _data;

    modifier authorized() {
        require(_comptroller.access(_key, msg.sender), string(abi.encodePacked(_key," access required.")));
        _;
    }

    constructor(string __name, 
                string __symbol,
                address __comptroller,
                string __key) 
                ERC721Token(__name,__symbol) {
                    require(__comptroller != address(0), "'__comptroller' cannot be equal to burn address.");
                    _comptroller = IBSFComptroller(__comptroller);
                    _key = __key;
                }

    function mint(bytes32 id, string data) 
             external
             authorized {
        uint256 next = _id.nextId();
        _mint(msg.sender, next);
        _data[next] = TokenData({id:id,data:data});
    }

    // function multiMint(bytes32 id, string[] data) 
    //          external
    //          authorized {
    //     uint256 next = _id.nextId();
    //     for(uint16 i = uint16(0); i < data.length - 1; i += 1){
    //       if(i != 0) {
    //         next = _id.nextId();
    //       }
    //       _mint(msg.sender, next);
    //       _data[next] = TokenData({id:id,data:data[i]});
    //     }
    // }
}