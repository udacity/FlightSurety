pragma solidity ^0.4.25;

interface IFlightSuretyData {
  function registerAirline(address airline) external;
  function isOperational() external view returns(bool);
  function isParticipatingAirline(address airline) external view returns(bool);
  function isRegisteredAirline(address airline) external view returns(bool);
  function getNumberOfParticipatingAirlines() external view returns(uint);
  function getNumberOfRegisteredAirlines() external view returns(uint);
}