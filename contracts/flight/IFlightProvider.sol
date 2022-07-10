// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFlightProvider {
    function fee() external view returns(uint256 fee_);
    /**
     * @dev Get(s) an flight 'object' by name.
     * @param airline airline the flight is with.
     * @param flight flight number.
     * @param timestamp flight departure (original)
     */
    function getFlight(string airline, string flight, uint256 timestamp) external view returns(bytes32,string memory,bool,string memory,uint8,uint256);

    /**
     * @dev Gets an airline id by name.
     * @param airline airline the flight is with.
     * @param flight flight number.
     * @param timestamp flight departure (original)
     */
    function getFlightId(bytes32 airline, string flight, uint256 timestamp) external view returns(bytes32 id);
    
    /**
    * @dev Checks an airlines registration.
    * @param airline airline the flight is with.
    * @param flight flight number.
    * @param timestamp flight departure (original)
    */
    function isFlightRegistered(bytes32 airline, string flight, uint256 timestamp) external view returns(bool);
    
    /**
     * @dev register a flight.
     * @param status initial flight status.
     * @param airline airline the flight is with.
     * @param flight flight number.
     * @param timestamp flight departure (original)
     */
    function registerFlight(uint8 status, bytes32 airline, string flight, uint256 timestamp) external;
}