import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';

import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

/**
 * The current oracle set.
 * @type {{}}
 */
let oracles = {};

/**
 * Maximum oracle threshold.
 * @type {number}
 */
const MAX_ORACLE_COUNT = 20;
/**
 * Unknown status.
 * @type {number}
 */
const STATUS_CODE_UNKNOWN = 0;
/**
 * On-time status.
 * @type {number}
 */
const STATUS_CODE_ON_TIME = 10;
/**
 * Late - Airline Fault status.
 * @type {number}
 */
const STATUS_CODE_LATE_AIRLINE = 20;
/**
 * Late - Weather Fault status.
 * @type {number}
 */
const STATUS_CODE_LATE_WEATHER = 30;
/**
 * Late - Technical Fault status.
 * @type {number}
 */
const STATUS_CODE_LATE_TECHNICAL = 40;
/**
 * Late - Other Fault status.
 * aka. Act of God
 * @type {number}
 */
const STATUS_CODE_LATE_OTHER = 50;
/**
 * Accessor for status codes.
 * @type {number[]}
 */
const STATUS_CODES = [
    STATUS_CODE_UNKNOWN,
    STATUS_CODE_ON_TIME,
    STATUS_CODE_LATE_AIRLINE,
    STATUS_CODE_LATE_WEATHER,
    STATUS_CODE_LATE_TECHNICAL,
    STATUS_CODE_LATE_OTHER
]

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

web3.eth.getAccounts((error, accts) => {
    const owner = accts[0];
    flightSuretyData.methods
        .authorizeCaller(config.appAddress)
        .send({ from: owner }, (error, authorized) => {
            if (error) {
                return console.log("Authorize Error:", error.message);
            }
            console.log("Owner Authorized: ", authorized);
            flightSuretyApp.methods
                .getRegistrationFee()
                .call({ from: owner }, (error, registrationFee) => {
                    if (error) {
                        return console.log("Get Registration Fee Error: ", error.message);
                    }

                    // Register the oracles
                    // Starting with 1 because we used accounts[0] as contract owner
                    // Setting gas limit to max allowed by ganache-cli configuration in truffle.js
                    for (let index = 1; index < MAX_ORACLE_COUNT; index++) {
                        flightSuretyApp.methods
                            .registerOracle()
                            .send({ from: accts[index], value: registrationFee, gas: 9999999 },
                                (error, result) => {
                                    if (error) {
                                        return console.log(`Error registering oracle: ${accts[index]} | ${error.message}`);
                                    }
                                    flightSuretyApp.methods
                                        .getMyIndexes()
                                        .call({ from: accts[index] }, (error, indexes) => {
                                            if (error) {
                                                return console.log("Get Indexes Error: ", error.message);
                                            }
                                            oracles[accts[index]] = indexes;
                                        });
                                }
                            );
                    }
                });
        });
});


flightSuretyApp.events.OracleRequest({ fromBlock: 0 },
    function (error, event) {
        if (error) console.log(error);
        const { index, airline, flight, timestamp } = event.returnValues;
        const statusCode =
            STATUS_CODES[Math.floor(Math.random() * STATUS_CODES.length)];
        Object.keys(oracles).forEach(oracle => {
            if (oracles[oracle].includes(index)) {
                flightSuretyApp.methods
                    .submitOracleResponse(index, airline, flight, timestamp, statusCode)
                    .send({ from: oracle, gas: 9999999 }, (error, result) => {
                        if (error) {
                            console.log("Error submitting Oracle response: ", error.message);
                        } else {
                            console.log(
                                `Oracle ${oracle} submitted response with status code ${statusCode}`
                            );
                        }
                    });
            }
        });
    }
);

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


