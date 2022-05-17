// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract OracleData {
    using SafeMath for uint256;

    // struct ResponseInfo {
    //     uint8 status;
    //     uint256 timestamp;
    // }

    // uint256 private REGISTRATION_FEE = 0.1 ether;

    // uint8 private nonce = 0;

    // event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // // Event fired when flight status request is submitted
    // // Oracles track this and if they have a matching index
    // // they fetch data and submit a response
    // event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // // Register an oracle with the contract
    // function registerOracle
    //                         (
    //                         )
    //                         external
    //                         payable
    // {
    //     // Require registration fee
    //     require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

    //     uint8[3] memory indexes = generateIndexes(msg.sender);

    //     _oracles[msg.sender] = Oracle({
    //                                     isRegistered: true,
    //                                     indexes: indexes
    //                                 });
    // }

    // /**
    //  * @dev Returns array of three non-duplicating integers from 0-9
    //  */ 
    // struct Oracle {
    //     bool registered;
    //     uint8[3] indexes;        
    // }

    // /**
    //  * @dev Registered oracles.
    //  */
    // mapping(address => Oracle) private _oracles;

    // /**
    //  * @dev Oracle responses.
    //  * @dev Key = hash(index, flight, timestamp)
    //  */
    // mapping(bytes32 => ResponseInfo) private _oracleResponses;

    // /**
    //  * @dev Event fired each time an oracle submits a response
    //  */
    // event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    // /**
    //  * @dev TODO: Document
    //  */
    // event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // /**
    //  * @dev Event fired when flight status request is submitted.
    //  * @dev Oracles track this and if they have a matching index they fetch data and submit a response.
    //  */
    // event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // /**
    //  * @dev TODO: Document
    //  */
    // function getIndexes
    //                         (
    //                         )
    //                         view
    //                         external
    //                         returns(uint8[3])
    // {
    //     require(_oracles[msg.sender].isRegistered, "Not registered as an oracle");

    //     return _oracles[msg.sender].indexes;
    // }

    // /**
    //  * @return {array:int} of three non-duplicating integers from 0-9
    //  */
    // function generateIndexes
    //                         (                       
    //                             address account         
    //                         )
    //                         internal
    //                         returns(uint8[3])
    // {
    //     uint8[3] memory indexes;
    //     indexes[0] = getRandomIndex(account);
        
    //     indexes[1] = indexes[0];
    //     while(indexes[1] == indexes[0]) {
    //         indexes[1] = getRandomIndex(account);
    //     }

    //     indexes[2] = indexes[1];
    //     while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
    //         indexes[2] = getRandomIndex(account);
    //     }

    //     return indexes;
    // }

    // function getIndexes
    //                         (
    //                         )
    //                         view
    //                         external
    //                         returns(uint8[3])
    // {
    //     require(_oracles[msg.sender].isRegistered, "Not registered as an oracle");
    //     return _oracles[msg.sender].indexes;
    // }

    // /**
    //  * @return {array:int} of three non-duplicating integers from 0-9
    //  */
    // function getRandomIndex
    //                         (
    //                             address account
    //                         )
    //                         internal
    //                         returns (uint8)
    // {
    //     uint8 maxValue = 10;

    //     // Pseudo random number...the incrementing nonce adds variation
    //     uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

    //     if (nonce > 250) {
    //         nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
    //     }

    //     return random;
    // }

    // /**
    // * @dev Called after oracle has updated flight status
    // */  
    // function _setFlightStatus
    //                             (
    //                                 address airline,
    //                                 string memory flight,
    //                                 uint256 timestamp,
    //                                 uint8 statusCode
    //                             )
    //                             internal
    //                             pure
                                
    // {
        
    // }

    // // Called by oracle when a response is available to an outstanding request
    // // For the response to be accepted, there must be a pending request that is open
    // // and matches one of the three Indexes randomly assigned to the oracle at the
    // // time of registration (i.e. uninvited oracles are not welcome)
    // /**
    //  * @dev Registers an oracle.
    //  */
    // function registerOracle
    //                         (
    //                         )
    //                         external
    //                         payable
    // {
    //     // Require registration fee
    //     require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

    //     uint8[3] memory indexes = generateIndexes(msg.sender);

    //     _oracles[msg.sender] = Oracle({
    //                                     registered: true,
    //                                     indexes: indexes
    //                                 });
    // }

    // // Called by oracle when a response is available to an outstanding request
    // // For the response to be accepted, there must be a pending request that is open
    // // and matches one of the three Indexes randomly assigned to the oracle at the
    // // time of registration (i.e. uninvited _oracles are not welcome)
    // function submitOracleResponse
    //                     (
    //                         uint8 index,
    //                         address airline,
    //                         string flight,
    //                         uint256 timestamp,
    //                         uint8 statusCode
    //                     )
    //                     external
    // {
    //     require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


    //     bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
    //     require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

    //     oracleResponses[key].responses[statusCode].push(msg.sender);

    //     // Information isn't considered verified until at least MIN_RESPONSES
    //     // oracles respond with the *** same *** information
    //     emit OracleReport(airline, flight, timestamp, statusCode);
    //     if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
    //     require((_oracles[msg.sender].indexes[0] == index) || (_oracles[msg.sender].indexes[1] == index) || (_oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


    //     bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
    //     require(_oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

    //     _oracleResponses[key].responses[statusCode].push(msg.sender);

    //     // Information isn't considered verified until at least MIN_RESPONSES
    //     // _oracles respond with the *** same *** information
    //     emit OracleReport(airline, flight, timestamp, statusCode);
    //     if (_oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

    //         emit FlightStatusInfo(airline, flight, timestamp, statusCode);

    //         // Handle flight status as appropriate
    //         _setFlightStatus(airline, flight, timestamp, statusCode);
    //     }
    // }
}