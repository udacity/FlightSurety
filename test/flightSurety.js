
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const truffleAssert = require("truffle-assertions");

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
      let status = await config.flightSuretyData.isOperational.call();
      assert.equal(status, true, "Incorrect operating status value");
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      let status = await config.flightSuretyData.isOperational.call();
      assert.equal(status, false, "Incorrect operating status value");
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSuretyData.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");
      let status = await config.flightSuretyData.isOperational.call();
      assert.equal(status, false, "Incorrect operating status value");

      let mode = await config.flightSuretyData.getTestingMode.call();
      assert.equal(mode, false, "Incorrect testing mode");


      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);
  });


  it('(airline) registers first airline when deployed', async () => {
    let result = await config.flightSuretyData.isRegisteredAirline.call(config.firstAirline);
    assert.equal(result, true, "First airline is not registered");
  });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isRegisteredAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) registered airline can fund the contract and become participating airline', async () => {
    const tx1 = await config.flightSuretyData.fund({ from: config.firstAirline, value: web3.utils.toWei('5', "ether") });
    const tx2 = await config.flightSuretyData.fund({ from: config.firstAirline, value: web3.utils.toWei('5', "ether") });
    truffleAssert.eventEmitted(tx2, "Participating", null, "Invalid event emitted"); 
    let result = await config.flightSuretyData.isRegisteredAirline.call(config.firstAirline);
    assert.equal(result, true, "Airline did become participating airline");
    let contractBalance = await web3.eth.getBalance(config.flightSuretyData.address);
    console.log(contractBalance);
  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isRegisteredAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
 

});
