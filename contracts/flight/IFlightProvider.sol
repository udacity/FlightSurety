// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFlightProvider {
    /**
     * Get(s) the currently configured fee.
     */
    function fee() external view returns(uint256 fee_);
    /**
     * Set(s) the fee for a key.
     */
    function setFee(uint256 value_) external returns(bool r);
    /**
     * @dev Get(s) an flight 'object' by name.
     * @param timestamp flight departure (original)
     */
    function getFlight(string calldata, uint256 timestamp) external returns(bytes32,string memory,bool,bytes32,uint8,uint256);

    /**
     * @dev Gets an airline id by name.
     * @param timestamp flight departure (original)
     */
    function getFlightId(string calldata, uint256 timestamp) external view returns(bytes32 id);
    
    /**
    * @dev Checks an airlines registration.
    * @param timestamp flight departure (original)
    */
    function isFlightRegistered(string calldata, uint256 timestamp) external view returns(bool);
    
    /**
     * @dev register a flight.
     * @param status initial flight status.
     * @param airline airline the flight is with.
     * @param timestamp flight departure (original)
     */
    function registerFlight(uint8 status, bytes32 airline, string calldata, uint256 timestamp) external returns(bytes32);
}