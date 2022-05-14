// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract AirlineData {
    using SafeMath for uint256;

    string private _bsf_airline = "bsf.airline";
    string private _bsf_airline_vote = "bsf.airline.vote";

    uint256 private _airlineCount;

    /**
    * @dev Defines an airline.
    */
    struct Airline {
        address account;
        string name;
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

    /**
    * @dev Event for airline registration.
    */
    event AirlineRegistered(bytes32 id, string name, address indexed account);
    /**
    * @dev Event for airline status change, operational / non-operational.
    */
    event AirlineStatusChange(address indexed account, bool operational);
    /**
    * TODO: Document
    */
    event AirlineVoteRegistered(bytes32 id, bool choice, address indexed account);

    function getAirlineCount() external view returns(uint256 count) {
        count = _airlineCount;
    }

    function _getAirlineId(string memory name) private view returns(bytes32 id){
        return keccak256(abi.encodePacked(_bsf_airline, name));
    }

    /**
     * @dev Gets an airline id by name.
     */
    function getAirlineId(string calldata name) external view returns(bytes32 id){
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
        return _getAirlineId(name);
    }

    function _isAirlineRegistered(string memory name) private view returns(bool){
        bytes32 id = _getAirlineId(name);
        return airlines[id].account != address(0);
    }
    /**
    * @dev Checks an airlines registration.
    */
    function isAirlineRegistered(string calldata name) external view returns(bool) {
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
        return _isAirlineRegistered(name);
    }

    function _isAirlineOperational(string memory name) private view returns(bool){
        return airlines[keccak256(abi.encodePacked(_bsf_airline,name))].isOperational;
    }

    /**
    * @dev Checks an airlines operational status.
    */
    function isAirlineOperational(string calldata name) external view returns(bool){
        bytes memory temp = bytes(name);
        require(temp.length > 0, "'name' must be a valid string.");
        return _isAirlineOperational(name);
    }

    function _existsAirline(string memory name) private returns(bool){
        bytes32 id = _getAirlineId(name);
        return airlines[id].account != address(0);
    }

    function _getAirline(string memory name) private returns(bytes32,address,string memory,bool,bool,uint256){
        bytes32 id = _getAirlineId(name);
        Airline ret = airlines[id];
        return (id,ret.account,ret.name,ret.registered,ret.operational,ret.vote);
    }
    /**
     * Get(s) an airline 'object' by name.
     */
    function getAirline(string memory name) 
        external 
        requireOperational 
        returns(address,string memory,bool,bool,uint256) {
            bytes memory temp = bytes(name);
            require(temp.length > 0, "'name' must be a valid string.");
            return _getAirline(name);
    }
    /**
    * @dev Registers an account as an airline.
    */
    function _registerAirline(address account, string memory name, bool operational, uint256 period) private returns(bool success) {
        bytes32 id = _getAirlineId(name);
        _airlines[id] = Airline({
            account: account,
            isOperational: operational,
            vote: period
        });
        emit AirlineRegistered(id, name, operational, period);
        success = true;
    }

    function _registerAirlineVote(bytes32 id, bool choice) private {
        _votes[id].push(choice);
        emit AirlineVoteRegistered(id, choice, msg.sender);
    }
   /**
    * @dev Add an airline to the registration queue
    * @dev Can only be called from FlightSuretyApp contract
    */   
    function registerAirline(address account, string memory name)
        external
        pure
        requireOperational
        returns (bool registered) {
            uint256 id = keccak256(abi.encodePacked(_bsf_airline,name));
            require(_airlines[id].registered == false, "Airline is already registered.");
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
    function registerAirlineVote(string memory name, bool choice)
        external
        pure
        requireOperational
        returns(bool registered) {
            require(_existsAirline(name), "The airline must exist.");
            (uint256 id,,,,,uint256 vote) = _getAirline(name);
            uint256 stamp = block.timestamp;
            require((stamp - vote) > 0, "The voting period has expired.");
            registered = _registerAirlineVote(id, choice);
    }
}