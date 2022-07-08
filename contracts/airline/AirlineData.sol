// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BSF/BSFContract.sol";

import "../utils/IProvider.sol";
import "../utils/IFeeProvider.sol";

import "./IAirlineProvider.sol";

contract AirlineData is BSFContract, IProvider, IFeeProvider, IAirlineProvider {
    using SafeMath for uint256;

    uint256 internal _airlineCount;

    /**
    * @dev Defines an airline.
    */
    struct Airline {
        /**
         * @dev Account that the airline has verified.
         */
        address account;
        string name;
        /**
         * @dev operational status of airline for contract purposes.
         */
        bool operational;
        /**
         * @dev Vote expiration timestamp
         */
        uint256 period;
        /**
         * @dev Operational votes received
         */
        uint256 votes;
        /**
         * @dev Operation vote threshold
         */
        uint256 threshold;
    }

    /**
    * @dev Current registration rate for airlines.
    */
    uint256 private _fee = 1 ether;

    /**
     * @dev Current vote period.
     */
    uint256 private _period = 2 days;

    /**
    * @dev Airlines accessor.
    */
    mapping(bytes32 => Airline) _airlines;

    mapping(bytes32 => bool) _voted;

    /**
    * @dev Event for airline registration.
    */
    event AirlineRegistered(bytes32 id, string name, address indexed account, uint256 period);
    /**
    * @dev Event for airline status change, operational / non-operational.
    * @param id {airline id}
    * @param operational {operational status}
    */
    event AirlineStatusChange(bytes32 id, bool operational);
    /**
    * @dev Event for Airline Vote Registration
    * @param id {airline id}
    * @param vid {voter id}
    * @param choice {yay / nay}
    */
    event AirlineVoteRegistered(bytes32 id, bytes32 vid, bool choice);

    constructor(address __comptroller, string __key) 
        BSFContract(__comptroller, __key) {}

    function getAirlineCount() external returns(uint256 count) {
        count = _airlineCount;
    }

    function _getAirlineId(string memory name) private view returns(bytes32 id){
        return keccak256(abi.encodePacked(_key, name));
    }

    /**
     * @dev Gets an airline id by name.
     */
    function getAirlineId(string name) external requireValidString(name) returns(bytes32 id){
        return _getAirlineId(name);
    }

    function _isAirlineRegistered(string memory name) private view returns(bool){
        bytes32 id = _getAirlineId(name);
        return _airlines[id].account != address(0);
    }
    /**
    * @dev Checks an airlines registration.
    */
    function isAirlineRegistered(string name) 
                external 
                view
                requireValidString(name) returns(bool) {
        return _isAirlineRegistered(name);
    }

    function _isAirlineOperational(string memory name) private view returns(bool){
        return _airlines[_getAirlineId(name)].operational;
    }

    /**
    * @dev Checks an airlines operational status.
    */
    function isAirlineOperational(string name) 
             external  
             requireValidString(name)
             returns(bool){
                return _isAirlineOperational(name);
    }

    function _existsAirline(string memory name) private returns(bool){
        bytes32 id = _getAirlineId(name);
        return _airlines[id].account != address(0);
    }

    function _getAirline(string memory name) private returns(bytes32,address,string memory,bool,uint256){
        bytes32 id = _getAirlineId(name);
        Airline ret = _airlines[id];
        return (id,ret.account,ret.name,ret.operational,ret.votes);
    }
    /**
     * Get(s) an airline 'object' by name.
     */
    function getAirline(string name) 
        external 
        requireOperational 
        requireValidString(name)
        returns(bytes32,address,string memory,bool,uint256) {
            return _getAirline(name);
    }

    function _getVoteId(bytes32 id_, address voter) internal returns(bytes32 id) {
        id = keccak256(abi.encodePacked(id_, voter));
    }

    /**
    * @dev Registers an account as an airline.
    * @todo Create _getThreshold to determine the number of airlines that exact and the threshold of votes required to register.
    */
    function _registerAirline(address account, string memory name, bool operational, uint256 period) internal returns(bool success) {
        bytes32 id = _getAirlineId(name);
        _airlines[id] = Airline({
            account: account,
            name: name,
            operational: operational,
            votes: period,
            threshold: 0,
            period: period
        });
        emit AirlineRegistered(id, name, account, period);
        success = true;
    }

    function _registerAirlineVote(bytes32 airlineId, bytes32 voterId, bool choice) internal returns(bool) {
        if(choice) {
            _airlines[airlineId].votes.add(1);
        }

        _voted[voterId] = true;
        
        emit AirlineVoteRegistered(airlineId, voterId, choice);
        return true;
    }
   /**
    * @dev Add an airline to the registration queue
    * @dev Can only be called from FlightSuretyApp contract
    */   
    function registerAirline(address account, string name)
        external
        pure
        requireOperational
        returns (bool registered) {
            require(!_existsAirline(name), "Airline is already registered.");
            if(_airlineCount <= 2) {
                registered = _registerAirline(account, name, true, uint256(0));
                return;
            }
            uint256 period = block.timestamp.add(_period);
            registered = _registerAirline(account, name, false, period);
    }

    /**
     * @dev Registers an airline vote.
     */
    function registerAirlineVote(string name, bool choice)
        external
        pure
        requireOperational
        returns(bool registered) {
            require(_existsAirline(name), "The airline must exist.");
            (bytes32 id,,,,uint256 vote) = _getAirline(name);
            uint256 stamp = block.timestamp;
            require((stamp - vote) > 0, "The voting period has expired.");
            bytes32 voteId = _getVoteId(id, msg.sender);
            require(_voted[voteId] != true, "No more votes left to cast.");
            registered = _registerAirlineVote(id, voteId, choice);
    }
}