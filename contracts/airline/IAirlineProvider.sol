// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IAirlineProvider {
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

    /**
     * @dev Gets the current fee for interactions.
     */
    function fee() external view returns(uint256 fee_);

    /**
     * @dev Gets the current airline count.
     */
    function getAirlineCount() external view returns(uint256 count);

    /**
     * @dev Gets an airline id by name.
     */
    function getAirlineId(string calldata) external view returns(bytes32 id);

    /**
    * @dev Checks an airlines registration.
    */
    function isAirlineRegistered(string calldata) external view returns(bool);

    /**
    * @dev Checks an airlines operational status.
    */
    function isAirlineOperational(string calldata) external view returns(bool);

    /**
     * Get(s) an airline 'object' by name.
     */
    function getAirline(string calldata) external view returns(address,string memory,bool,bool,uint256);

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