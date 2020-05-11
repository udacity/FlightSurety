import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const TEST_ORACLES = 20;
const FIRST_ORACLE_INDEX = 10;
let oracles = [];

// Register oracles
initOracles(TEST_ORACLES);

async function initOracles(num) {
  let accounts = await web3.eth.getAccounts();
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call({
    from: accounts[0]
  })

  console.log(fee);

  for (let i = FIRST_ORACLE_INDEX; i < FIRST_ORACLE_INDEX + TEST_ORACLES; i++) {
    try {
      await flightSuretyApp.methods.registerOracle().send({
        from: accounts[i],
        value: fee,
        gas: 3000000
      })
    } catch (e) {
      //console.log("Oracle is already registered")
    }
    let index = await flightSuretyApp.methods.getMyIndexes().call({
      from: accounts[i]
    });
    //console.log(`Oracle Inexes: [${index[0]}, ${index[1]}, ${index[2]}]`);
    oracles.push([accounts[i], index]);
  }
  console.log(oracles);
}

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    //if (error) console.log(error)
    //console.log(event)
    console.log(event.returnValues);
    let index = event.returnValues.index;
    let airline = event.returnValues.airline;
    let flight = event.returnValues.flight;
    let timestamp = event.returnValues.timestamp;
    let status = 20; //(Math.floor(Math.random() * Math.floor(5)) * 10);
    console.log("random status", status);
    for (let i = 0; i < oracles.length; i++) {
      for (let j = 0; j < 3; j++) {
        if (event.returnValues.index == oracles[i][1][j]) {
          console.log("submitOracleResponse from ", oracles[i][0]);
          flightSuretyApp.methods
          .submitOracleResponse(index, airline, flight, timestamp, status)
          .send({
            from: oracles[i][0],
            gas: 3000000
          },(error, result) => {
            if(!error){
                console.log(`Oracle ${oracles[i][0]} submitted flight status code of ${status}`)
            }       
            else {
                console.log(`oracle ${oracles[i][0]} was rejected`)
            }
          });
        }
      }
    }
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


