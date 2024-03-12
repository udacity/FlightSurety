var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 20;
  // Watch contract events
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;
  // var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address, { from: accounts[0] });
  });


  it('can register oracles', async () => {
    
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();
    oracleReg = true;
    // ACT
    let b;
    try{
      for(let a=0; a<TEST_ORACLES_COUNT-1; a++) {
        if(a > 19){
          b = a - 19;
        }else if(a > 9){
          b = a - 9;
        }else{
          b = a;}

        await config.flightSuretyApp.registerOracle({ from: accounts[b], value: Number(fee.toString()) });
        let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts[b]});
        console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
      }
    } catch(e){
      console.log(e);
      oracleReg = false;
    }

    assert.equal(oracleReg, true, "Oracles are not registered.");
  });

  it('can request flight status', async () => {
    
    oracleRequest = false;
    // ARRANGE
    let flight = 'ND1309'; // Course number
    let timestamp = Math.floor(Date.now() / 1000);
    // Submit a request for oracles to get status information for a flight
    await config.flightSuretyApp.fetchFlightStatus(config.firstAirline, flight, timestamp);
    // ACT

    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();
    let countOracleResponse = 0;
    let flightKey = -200;
    let b;
    for(let a=0; a<TEST_ORACLES_COUNT-1; a++) {
      if(a > 19){b = a - 19;}else if(a > 9){b = a - 9;}else{b = a;}
      await config.flightSuretyApp.registerOracle({ from: accounts[b], value: Number(fee.toString()) });
      // Get oracle information
      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[b]});
      console.log(`Oracle Registered: ${oracleIndexes[0]}, ${oracleIndexes[1]}, ${oracleIndexes[2]}`);
      for(let idx=0;idx<3;idx++) {
        try {
          // Submit a response...it will only be accepted if there is an Index match
          await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx], config.firstAirline, flight, timestamp, STATUS_CODE_ON_TIME, { from: accounts[b] });
          countOracleResponse = countOracleResponse + 1;
          flightKey = await config.flightSuretyApp.getFlightKey(oracleIndexes[idx], config.firstAirline, flight, timestamp);
          oracleRequest = true;
        }
        catch(e) {
          // Enable this when debugging
          // console.log(e);
          // console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp);
        }

      }
    }
    await config.flightSuretyApp.getResponseCounts.call(flightKey, STATUS_CODE_ON_TIME).then(result => {
      console.log('Number of events STATUS_CODE_ON_TIME : ', result.toString());
    });
    await config.flightSuretyApp.getFlightStatus.call(flight).then(result => {
      console.log('flight status code : ', result.toString());
    });

    let statusIsUpdated = await config.flightSuretyApp.getFlightStatus(flight);

    console.log('Oracle positive response : ' + countOracleResponse);
    assert.equal(statusIsUpdated, STATUS_CODE_ON_TIME, "Wrong flight status.");

  });
 
});