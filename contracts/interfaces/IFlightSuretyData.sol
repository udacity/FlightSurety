pragma solidity ^0.4.25;

interface IFlightSuretyData {
  function registerAirline(address airline) external;
  function isOperational() external view returns(bool);
  function isParticipatingAirline(address airline) external view returns(bool);
}