// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BsfContract.sol";

contract FlightData is BsfContract {
    using SafeMath for uint256;

    string private _bsf_flight = "bsf.flight";

    struct Flight {
        bool registered;
        uint8 status;
        uint256 timestamp;        
        address airline;
        string name;
    }

    mapping(bytes32 => Flight) private flights;

    function _getFlight(string memory name) 
        private 
        returns(bytes32,string memory,bool,address,uint8,uint256)
    {
        bytes32 id = _getFlightId(name);
        Flight ret = flights[id];
        return (id,ret.name,ret.registered,ret.airline,ret.status,ret.timestamp);
    }

    /**
     * Get(s) an flight 'object' by name.
     */
    function getFlight(string memory name) 
        external 
        requireOperational 
        returns(bytes32,string memory,bool,address,uint8,uint256) {
            bytes memory temp = bytes(name);
            require(temp.length > 0, "'name' must be a valid string.");
            return _getAirline(name);
    }

    function _getFlightId(string memory name, address airline, uint256 timestamp) private view returns(bytes32 id){
        return keccak256(abi.encodePacked(_bsf_flight, name));
    }

    /**
     * @dev Gets an airline id by name.
     */
    function getFlightId(string memory name, address airline, uint256 timestamp) external view returns(bytes32 id){
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
        return _getFlightId(name);
    }

    function _isFlightRegistered(string memory name, address airline, uint256 timestamp) private view returns(bool){
        return flights[_getFlightId(name, airline, timestamp)].registered;
    }
    
    /**
    * @dev Checks an airlines registration.
    */
    function isFlightRegistered(string memory name, address airline, uint256 timestamp) external view returns(bool) {
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
        return _isFlightRegistered(name, airline, timestamp);
    }
    
    function registerFlight(uint8 status, address airline, string flight, uint256 timestamp) external requireOperational {
        require(!_isFlightRegistered(flight, airline, timestamp), "Flight is already registered.");
    }

    function _registerFlight(uint8 status, address airline, string flight) {

    }
}