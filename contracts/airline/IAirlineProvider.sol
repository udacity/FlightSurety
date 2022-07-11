// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IAirlineProvider {
    /**
    * @dev Event for airline registration.
    */
    event AirlineRegistered(bytes32 id, string name, address indexed account, uint256 period);
    /**
    * @dev Event for airline status change, operational / non-operational.
    */
    event AirlineStatusChange(bytes32 id, bool operational);
    /**
    * TODO: Document
    */
    event AirlineVoteRegistered(bytes32 id, bytes32 vid, bool choice);

    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 fee_);
    /**
     * Set(s) the fee for a key.
     */
    function setFee(uint256 value_) external returns(bool r);

    /**
     * @dev Gets the current airline count.
     */
    function getAirlineCount() external returns(uint256 count);

    /**
     * @dev Gets an airline id by name.
     */
    function getAirlineId(string calldata) external returns(bytes32 id);

    /**
    * @dev Checks an airlines registration.
    */
    function isAirlineRegistered(string calldata) external returns(bool);

    /**
    * @dev Checks an airlines operational status.
    */
    function isAirlineOperational(string calldata) external returns(bool);

    /**
     * Get(s) an airline 'object' by name.
     */
    function getAirline(string calldata) external returns(bytes32,address,string memory,bool,uint256);

   /**
    * @dev Add an airline to the registration queue
    * @dev Can only be called from FlightSuretyApp contract
    */   
    function registerAirline(address account, string calldata) external returns (bool registered);

    /**
     * @dev Registers an airline vote.
     */
    function registerAirlineVote(string calldata, bool choice) external returns(bool registered);
}