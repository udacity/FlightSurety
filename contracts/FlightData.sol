// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightData {
    using SafeMath for uint256;

    string private _bsf_flight = "bsf.flight";

    struct Flight {
        bool registered;
        uint8 status;
        uint256 timestamp;        
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

    function registerFlight(uint8 status, string airline, string flight) external requireOperational {
        require(_existAirline(airline), "");
        keccak256(abi.encodePacked(_bsf_airline,name));
    }

    function _registerFlight(uint8 status, address airline, string flight) {

    }
}