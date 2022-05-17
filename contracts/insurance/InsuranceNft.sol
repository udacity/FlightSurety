// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../BSF/BSF721/BSF721.sol";

contract InsuranceNft is BSF721 {
    constructor(string __name, 
                string __symbol,
                address __comptroller,
                string __key) 
                BSF721(__name,__symbol,__comptroller,__key) {}
}