pragma solidity ^0.6.0;

interface IFlightSuretyData {
  function registerAirline(address airline) external;
  function isOperational() external view returns(bool);
  function isParticipatingAirline(address airline) external view returns(bool);
  function isRegisteredAirline(address airline) external view returns(bool);
  function getNumberOfParticipatingAirlines() external view returns(uint);
  function getNumberOfRegisteredAirlines() external view returns(uint);

  function buy(
                address passenger,
                address airline,
                string calldata flight,
                uint256 timestamp)
                external
                payable;

  function creditInsurees(
                            address passenger,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint256 credit
                          )
                          external;
  function pay(
                  address payable passenger
              )
              external;

}