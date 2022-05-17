// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSF/BsfContract.sol";

contract FlightData is BSFContract {
    using SafeMath for uint256;

    struct Flight {
        bool registered;
        uint8 status;
        uint256 timestamp;        
        address airline;
        string name;
    }

    mapping(bytes32 => Flight) private flights;

    constructor(address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {

    }

    function _getFlight(string memory name) 
        private 
        returns(bytes32,string memory,bool,string memory,uint8,uint256)
    {
        bytes32 id = _getFlightId(name);
        Flight ret = flights[id];
        return (id,ret.name,ret.registered,ret.airline,ret.status,ret.timestamp);
    }

    /**
     * Get(s) an flight 'object' by name.
     */
    function getFlight(string name) 
        external 
        requireOperational 
        requireValidString(name)
        returns(bytes32,string memory,bool,string memory,uint8,uint256) {
            return _getFlight(name);
    }

    function _getFlightId(string memory name, string airline, uint256 timestamp) private view returns(bytes32 id){
        id = keccak256(abi.encodePacked(_bsf_flight, name));
    }

    /**
     * @dev Gets an airline id by name.
     */
    function getFlightId(string name, string airline, uint256 timestamp) external view requireValidString(name) returns(bytes32 id){
        return _getFlightId(name);
    }

    function _isFlightRegistered(string memory name, string airline, uint256 timestamp) private view returns(bool){
        return flights[_getFlightId(name, airline, timestamp)].registered;
    }
    
    /**
    * @dev Checks an airlines registration.
    */
    function isFlightRegistered(string name, string airline, uint256 timestamp) external view requireValidString(name) returns(bool) {
        return _isFlightRegistered(name, airline, timestamp);
    }
    
    function registerFlight(uint8 status, string airline, string flight, uint256 timestamp) external requireOperational {
        require(!_isFlightRegistered(flight, airline, timestamp), "Flight is already registered.");
    }

    function _registerFlight(uint8 status, address airline, string flight) internal {

    }
}