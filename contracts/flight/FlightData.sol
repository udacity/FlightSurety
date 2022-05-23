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
        string airline;
        string name;
    }

    mapping(bytes32 => Flight) private flights;

    constructor(address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {

    }

    function _getFlight(bytes32 fid) 
        internal 
        returns(bytes32,string memory,bool,string memory,uint8,uint256)
    {
        Flight ret = flights[fid];
        return (fid,ret.name,ret.registered,ret.airline,ret.status,ret.timestamp);
    }

    /**
     * Get(s) an flight 'object' by name.
     */
    function getFlight(bytes32 fid) 
             external 
             requireOperational 
             returns(bytes32,string memory,bool,string memory,uint8,uint256) {
        return _getFlight(fid);
    }

    function _getFlightId(bytes32 aid, string name, uint256 timestamp) 
             internal 
             view 
             returns(bytes32 id){
        id = keccak256(abi.encodePacked(_bsf_flight, aid, name, timestamp));
    }

    /**
     * @dev Gets an airline id by name.
     */
    function getFlightId(bytes32 aid, string name, uint256 timestamp) 
             external 
             view 
             requireValidString(name) 
             returns(bytes32 id){
        return _getFlightId(aid,name,timestamp);
    }

    function _isFlightRegistered(bytes32 aid,string name, uint256 timestamp)
             internal 
             view 
             returns(bool){
        return flights[_getFlightId(aid, name, timestamp)].registered;
    }
    
    /**
    * @dev Checks an airlines registration.
    */
    function isFlightRegistered(bytes32 aid, string name, uint256 timestamp) 
             external 
             view 
             requireValidString(name)
             returns(bool) {
        return _isFlightRegistered(aid, name, timestamp);
    }
    
    function registerFlight(uint8 status, bytes32 aid, string flight, uint256 timestamp) 
             external 
             requireOperational {
        require(!_isFlightRegistered(aid, flight, timestamp), "Flight is already registered.");
    }

    function _registerFlight(uint8 status, address airline, string flight) internal {

    }
}