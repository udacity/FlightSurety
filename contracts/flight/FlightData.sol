// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSF/BsfContract.sol";
import "../utils/IProvider.sol";
import "../utils/IFeeProvider.sol";

import "./IFlightProvider.sol";

contract FlightData is BSFContract, IFlightProvider, IFeeProvider, IProvider {
    using SafeMath for uint256;

    struct Flight {
        bool registered;
        uint8 status;
        uint256 timestamp;        
        bytes32 airline;
        string name;
    }

    mapping(bytes32 => Flight) private flights;

    constructor(address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {

    }

    function _getFlight(bytes32 fid) 
        private 
        returns(bytes32,string,bool,bytes32,uint8,uint256)
    {
        Flight ret = flights[fid];
        return (fid,ret.name,ret.registered,ret.airline,ret.status,ret.timestamp);
    }

    /**
     * Get(s) an flight 'object' by name.
     */
    function getFlight(bytes32 aid, string name, uint256 timestamp) 
        external 
        requireOperational 
        requireValidString(name)
        returns(bytes32,string,bool,bytes32,uint8,uint256) {
            return _getFlight(_getFlightId(aid, name, timestamp));
    }

    function _getFlightId(bytes32 aid, string name, uint256 timestamp) 
            internal 
            view 
            returns(bytes32 id){
        id = keccak256(abi.encodePacked(_bsf_flight, name));
    }

    /**
     * @dev Gets an airline id by name.
     * @param aid {airline id}
     */
    function getFlightId(bytes32 aid, string name, uint256 timestamp) 
            external 
            view 
            requireValidString(name) 
            returns(bytes32 id){
        id = _getFlightId(aid,name,timestamp);
    }

    function _isFlightRegistered(bytes32 fid) 
        internal 
        view 
        returns(bool){
        return flights[fid].registered;
    }
    
    /**
    * @dev Checks an airlines registration.
    */
    function isFlightRegistered(bytes32 aid, string name, uint256 timestamp) 
                external 
                view 
                requireValidString(name) 
                returns(bool) {
        return _isFlightRegistered(_getFlightId(aid, name, timestamp));
    }
    
    function registerFlight(uint8 status, bytes32 aid, string flight, uint256 timestamp) 
                external 
                requireOperational 
                requireValidString(flight) {
        require(!_isFlightRegistered(_getFlightId(aid, flight, timestamp)), "Flight is already registered.");
    }

    function _registerFlight(uint8 status, address airline, string flight) internal {

    }
}