
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

var FlightSuretyData = artifacts.require("FlightSuretyData");

contract('Flight Surety Tests', async (accounts) => {

    beforeEach('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address, { from: accounts[0] });
        flightSuretyData = await FlightSuretyData.deployed();
        console.log("FlightSuretyData contract deployed at address:", flightSuretyData.address);
    });

    web3.eth.getBalance(accounts[0], (error, balance) => {
        if (error){
            console.error(error);
        } else {
            console.log(`Account ${accounts[0]} has a balance of ${web3.utils.fromWei(balance, "ether")} Ether`);
        }
    });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {
        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");
    });


  it(`(multiparty) can deny access to setOperatingStatus() for non-Contract Owner account`, async function () {
      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try{
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not limited to Contract Owner");
  });

  it(`(multiparty) can grant access to setOperatingStatus() for Contract Owner account`, async function () {
      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try{
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can deny access to functions using requireIsOperational when operating status is false`, async function () {
      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try{
        reverted = false;
        await config.flightSuretyApp.registerAirline(accounts[5], 'airline', { from: accounts[3] });
      }catch(e) {// console.log(e);
        reverted = true;}
      try{
        reverted = false;
        await config.flightSuretyData.buy(accounts[3], 'airline', { from: accounts[10] });
      }catch(e) {// console.log(e);
        reverted = true;}
      try{
        reverted = false;
        await config.flightSuretyData.creditInsurees('airline', { from: accounts[10] });
      }catch(e) {// console.log(e);
        reverted = true;}
      try{
        reverted = false;
        await config.flightSuretyData.pay({ from: accounts[10] });
      }catch(e) {// console.log(e);
        reverted = true;}
      try{
        reverted = false;
        await config.flightSuretyData.fund({ from: accounts[10], value: web3.utils.toWei('10', 'ether')});
      }catch(e) {// console.log(e);
        reverted = true;}
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);
  });

  it('airline account 1 is registered as an Airline', async () => {
    let result = true;
    try{
        result = await config.flightSuretyApp.isAirlineRegistered(config.firstAirline, {from: config.firstAirline});
    }
    catch(e){
        result = false;
    }
    assert.equal(result, true, "Airline is not registered.");
  });

  it(`(multiparty) Only existing airline may register a new airline until there are at least four airlines registered`, async function () {

    let airlnRegsrtionSuccess = true;
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    // first airline nee to fund the contract to register other airlines
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
    await config.flightSuretyApp.registerAirline(newAirline2, 'airlineName',{from: config.firstAirline}); // register second airline with first airline
    await config.flightSuretyData.fund({from: newAirline2, value: web3.utils.toWei('10', 'ether') }) // airline2 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline3, 'airlineName',{from: newAirline2}); // register third airline with second airline
    await config.flightSuretyData.fund({from: newAirline3, value: web3.utils.toWei('10', 'ether') }) // airline3 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline4, 'airlineName',{from: newAirline3}); // register fourth airline with third airline

    try{ // 1st airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(config.firstAirline, {from: config.firstAirline});
    }catch(e){airlnRegsrtionSuccess = false;}
    try{ // 2nd airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(newAirline2, {from: newAirline2});
    }catch(e){airlnRegsrtionSuccess = false;}
    try{ // 3rd airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(newAirline3, {from: newAirline3});
    }catch(e){airlnRegsrtionSuccess = false;}
    try{ // 4th airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(newAirline4, {from: newAirline4});
    }catch(e){airlnRegsrtionSuccess = false;}

    assert.equal(airlnRegsrtionSuccess, true, "Cannot register new airline with a single airline up to 4.");
  });

  it(`(multiparty) Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines - failure if only one vote`, async function () {

    let airlnRegsrtionSuccess = true;
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    // first airline need to fund the contract to register other airlines
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
    await config.flightSuretyApp.registerAirline(newAirline2, 'airlineName2',{from: config.firstAirline}); // register second airline with first airline

    await config.flightSuretyData.fund({from: newAirline2, value: web3.utils.toWei('10', 'ether') }) // airline2 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline3, 'airlineName3',{from: newAirline2}); // register third airline with second airline
  
    await config.flightSuretyData.fund({from: newAirline3, value: web3.utils.toWei('10', 'ether') }) // airline3 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline4, 'airlineName4',{from: newAirline3}); // register fourth airline with third airline
    await config.flightSuretyData.getNumberRegisteredAirline.call().then(result => {
      console.log('Number of registered airline : ', result.toString());
    });
    await config.flightSuretyData.fund({from: newAirline4, value: web3.utils.toWei('10', 'ether') }) // airline3 fund the contract to also register airilne

    await config.flightSuretyApp.registerAirline.call(newAirline5, 'airlineName5',{from: newAirline4}).then(result => {
      console.log('success on registering 5th airline with one other airline : ', result.success,' , number of votes received : ', result.votes.toString());
    }); // call to observe vote, but registration failure
    await config.flightSuretyApp.registerAirline(newAirline5, 'airlineName5',{from: newAirline4}); // register fifth airline with fourth airline

    try{ // 5th airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(newAirline5, {from: newAirline4});
    }catch(e){}

    assert.equal(airlnRegsrtionSuccess, false, "5th airline registration should not have been successful. Need 50% of vote to let it in.");
  });

  it(`(multiparty) Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines - success with 2 votes`, async function () {

    let airlnRegsrtionSuccess = false;
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    // first airline need to fund the contract to register other airlines
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
    await config.flightSuretyApp.registerAirline(newAirline2, 'airlineName2',{from: config.firstAirline}); // register second airline with first airline
    await config.flightSuretyData.fund({from: newAirline2, value: web3.utils.toWei('10', 'ether') }) // airline2 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline3, 'airlineName3',{from: newAirline2}); // register third airline with second airline
    await config.flightSuretyData.fund({from: newAirline3, value: web3.utils.toWei('10', 'ether') }) // airline3 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline4, 'airlineName4',{from: newAirline3}); // register fourth airline with third airline
    await config.flightSuretyData.fund({from: newAirline4, value: web3.utils.toWei('10', 'ether') }) // airline3 fund the contract to also register airilne
    await config.flightSuretyApp.registerAirline(newAirline5, 'airlineName5',{from: newAirline4}); // register fifth airline with fourth airline
    // await config.flightSuretyApp.registerAirline(newAirline5, 'airlineName',{from: newAirline3}); // register fifth airline with third airline

    await config.flightSuretyApp.registerAirline.call(newAirline5, 'airlineName5',{from: newAirline2}).then(result => {
      console.log('Success on registering 5th airline with votes from two airlines : ', result.success,' , number of votes received : ', result.votes.toString());
    }); // call to observe vote and registration succes
    await config.flightSuretyApp.registerAirline(newAirline5, 'airlineName5',{from: newAirline2}); // register fifth airline with 2nd airline

    try{ // 5th airline
      airlnRegsrtionSuccess = await config.flightSuretyApp.isAirlineRegistered(newAirline5, {from: newAirline4});
    }catch(e){}

    assert.equal(airlnRegsrtionSuccess, true, "5th airline registration should have been successful. 2 airlines voted it in.");
  });

  // If airline did not fund the contract, it cannot register an airline
  it('(airline) CANNOT register an Airline using registerAirline() if did not fund the contract', async () => {
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        let res = await config.flightSuretyApp.registerAirline(newAirline, 'airlineName',{from: config.firstAirline});
    }
    catch(e) {
      console.log('Registering Airline has been reverted');
    }

    await config.flightSuretyData.hasGivenFund(config.firstAirline).then(result => {
      console.log('Airline has given fund :', result);
    });
    
    let result = await config.flightSuretyApp.isAirlineRegistered(newAirline);
    
    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  // Test first airline CAN register an airline
  it('(airline) CAN register an Airline using registerAirline() if it has funded the contract', async () => {
    // ARRANGE
    let newAirline = accounts[2];

    // fund contract and confirm
    try {
        await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
        .then(result => {
            console.log('funding has worked :', result.receipt.status);
          });
    }
    catch(e) {
    }
    // check if funding has been successful
    await config.flightSuretyData.hasGivenFund(config.firstAirline).then(result => {
      console.log('Airline has given fund :', result);
    })
    .catch(error => {
      console.log('Error:', error);
    });
    // register new airline
    try {
        await config.flightSuretyApp.registerAirline(newAirline, 'airlineName',{from: config.firstAirline});
    }
    catch(e) {
      console.log('error reg airline last one : ', e);
    }

    let result = await config.flightSuretyApp.isAirlineRegistered(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

  });

// Test first airline CAN register an airline
it('(airline) CAN register a flight using registerFlight() if it is registered as an airline', async () => {
  // ARRANGE
  let result = true;

  // fund contract and confirm
  await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
    .then(result => {
        console.log('funding has worked :', result.receipt.status);
      });
  // check if funding has been successful
  await config.flightSuretyData.hasGivenFund(config.firstAirline).then(result => {
    console.log('Airline has given fund : ', result);
  });
  // register flight
  let flight = 'FL1309'; // Course number
  let timestamp = Math.floor(Date.now() / 1000);

  await config.flightSuretyApp.isFlightRegistered.call(flight).then(result => {
    console.log('BEFORE REGISTRATION : ', result);
  });

  try{
    await config.flightSuretyApp.registerFlight(flight,0,timestamp, {from: config.firstAirline}).then(result => {
      console.log('Transaction receipt register flight : ', result.receipt.status);
  });
  } catch(e){
    result = false;
    console.log('Error is : ', e);
  }
  await config.flightSuretyApp.isFlightRegistered.call(flight).then(result => {
    console.log('flight is registered : ', result);
  });
  // ASSERT
  assert.equal(result, true, "Airline should be able to register a flight");

});

  it('Unauthorize the app to register airline with unAuthorizeCaller()', async () => {
    result = true;
    let newAirline1 = accounts[2];
    let newAirline2 = accounts[3];

    // fund contract with existing airline so it is allowed to register others
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') })
        .then(result => {
            console.log('funding has worked :', result.receipt.status);
    });

    // first airline should be able to be registered as app authorized
    await config.flightSuretyApp.registerAirline.call(newAirline1, 'airlineName',{from: config.firstAirline}).then(result => {
      console.log('Airline1 is registered :', result.success, ' , number of votes received for registration : ', result.votes.toString());
    });
    await config.flightSuretyApp.registerAirline(newAirline1, 'airlineName',{from: config.firstAirline});

    // unauthorize the app to work
    await config.flightSuretyData.unAuthorizeCaller(config.flightSuretyApp.address);

    // if the app is unauthorized the next airline should not be able to be registered
    try {
      await config.flightSuretyData.registerAirline(newAirline2, 'airlineName',{from: config.firstAirline});
    }
    catch(e) {
      result = false;
    }

    assert.equal(result, false, "App is still authorized.");
});

it('Insurance can be bought for an airline flight', async () => {
    let result = true;

    // fund the contract so customer can purchase insurance
    await config.flightSuretyData.fund.call({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') }).then(result => {
      console.log('Airline has funded the contract : ', result);
    });
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') });

    await config.flightSuretyApp.registerFlight.call('flightName', 0, 1691094961,{from: config.firstAirline}).then(result => {
      console.log('Flight has been registered : ', result);
    });

    try{
      await config.flightSuretyApp.registerFlight('flightName', 0, 1691094961,{from: config.firstAirline});
    }catch(e){
      // console.log(e);
    }

    await config.flightSuretyData.buy.call(config.firstAirline, 'flightName', { from: accounts[8], value: web3.utils.toWei('0.1', 'ether') }).then(result => {
      console.log('Customer bought insurance : ', result);
    });
    try{
      await config.flightSuretyData.buy(config.firstAirline, 'flightName', { from: accounts[8], value: web3.utils.toWei('0.1', 'ether') });
    }catch(e){
      console.log(e);
      result = false;
    }
    assert.equal(result, true, "Insurance could not be bought for the flight.");
});

it('Insurance purchase is not allowed if price is over 1 ether', async () => {
  let result = true;
  let result2 = true;
  // fund the contract so customer can purchase insurance
  await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') });
  await config.flightSuretyApp.registerFlight('flightName', 0, 1691094961,{from: config.firstAirline});
  try{
    await config.flightSuretyData.buy(config.firstAirline, 'flightName', { from: accounts[8], value: web3.utils.toWei('1', 'ether') });
  }catch(e){
    result = false;
  }
  assert.equal(result, true, "Insurance should not be purchased if input higher than 1 ether.");

  try{
    await config.flightSuretyData.buy(config.firstAirline, 'flightName', { from: accounts[8], value: web3.utils.toWei('2', 'ether') });
  }catch(e){
    result2 = false;
  }
  assert.equal(result2, false, "Insurance should not be purchased if input higher than 1 ether.");
});

it('If flight is delayed and credit is paid, customer can receive his fund', async () => {
  let result = true;
  // fund the contract so customer can purchase insurance
  await config.flightSuretyData.fund({from: config.firstAirline, value: web3.utils.toWei('10', 'ether') });
  await config.flightSuretyApp.registerFlight('flightName', 0, 1691094961,{from: config.firstAirline});
  await config.flightSuretyData.buy(config.firstAirline, 'flightName', { from: accounts[8], value: web3.utils.toWei('1', 'ether') });

  await config.flightSuretyData.creditInsurees.call('flightName',{from: config.firstAirline}).then(result => {
          console.log('Insuree has been credited : ', result);
  });
  await config.flightSuretyData.creditInsurees('flightName',{from: config.firstAirline});

  await config.flightSuretyData.pay.call({ from: accounts[8]}).then(result => {
    console.log('Customer received the money : ', result.toString());
  });

  await config.flightSuretyData.getContractBalance.call().then(result => {
    console.log('Account PRIOR paying : ', (result/1000000000000000000).toString());
  });

  try{
    await config.flightSuretyData.pay({ from: accounts[8]});

  }catch(e){
    result = false;
  }

  await config.flightSuretyData.getContractBalance.call().then(result => {
    console.log('Account AFTER paying : ', (result/1000000000000000000).toString());
  });

  assert.equal(result, true, "Customer should have received his money.");
});

});