// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../BSF/BSF721/BSF721.sol";

contract FlightNft is BSF721 {
    constructor(string __name, 
                string __symbol,
                address __comptroller,
                string __key) 
                BSF721(__name,__symbol,__comptroller,__key) {}
}
