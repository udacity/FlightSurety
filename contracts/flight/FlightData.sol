// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSF/BSFContract.sol";

import "./IFlightProvider.sol";

contract FlightData is BSFContract, IFlightProvider {
    using SafeMath for uint256;

    /**
    * @dev Current registration rate for flights.
    */
    uint256 internal _fee = 0.01 ether;

    struct Flight {
        bool registered;
        uint8 status;
        uint256 timestamp;        
        bytes32 airline;
        string name;
    }

    mapping(bytes32 => Flight) internal flights;

    constructor(address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {}

    function fee() external view returns(uint256 fee_){
        fee_ = _fee;
    }

    function setFee(uint256 value_) external authorized returns(bool r){
        _fee = value_;
        r = _fee == value_;
    }

    function _getFlight(bytes32 fid) 
        internal 
        returns(bytes32,string,bool,bytes32,uint8,uint256)
    {
        Flight storage ret = flights[fid];
        return (fid,ret.name,ret.registered,ret.airline,ret.status,ret.timestamp);
    }

    /**
     * Get(s) an flight 'object' by name.
     */
    function getFlight(string name, uint256 timestamp) 
        external 
        requireOperational 
        requireValidString(name)
        returns(bytes32,string,bool,bytes32,uint8,uint256) {
            return _getFlight(_getFlightId(name, timestamp));
    }

    function _getFlightId(string name, uint256 timestamp) 
            internal 
            view 
            returns(bytes32 id){
        id = keccak256(abi.encodePacked(_bsf_flight, name, timestamp));
    }

    /**
     * @dev Gets an flight id by name, timestamp.
     * @param name {flight name}
     */
    function getFlightId(string name, uint256 timestamp) 
            external 
            view 
            requireValidString(name) 
            returns(bytes32 id){
        id = _getFlightId(name,timestamp);
    }

    function _isFlightRegistered(bytes32 fid) 
        internal 
        view 
        returns(bool){
        return flights[fid].registered;
    }

    function _isFlightRegistered(string name, uint256 timestamp)
             internal 
             view 
             returns(bool){
        return flights[_getFlightId(name, timestamp)].registered;
    }
    
    /**
    * @dev Checks an airlines registration.
    */
    function isFlightRegistered(string name, uint256 timestamp) 
                external 
                view 
                requireValidString(name) 
                returns(bool) {
        return _isFlightRegistered(_getFlightId(name, timestamp));
    }
    
    function registerFlight(uint8 status, bytes32 aid, string flight, uint256 timestamp) 
                external 
                requireOperational 
                requireValidString(flight) returns(bytes32) {
        require(!_isFlightRegistered(_getFlightId(flight, timestamp)), "Flight is already registered.");

        return _registerFlight(status ,aid, flight, timestamp);
    }

    function _registerFlight(uint8 status, bytes32 aid, string flight, uint256 timestamp)
            internal
            returns(bytes32) {
                // TODO: Register flight
            return keccak256("test");
    }
}