var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

let testPassenger;

let testFirstFlightID;
let testSecondFlightID;
let testFirstCity;
let testSecondCity;

contract('Flight Surety Tests', async (accounts) => {
  //console.log(accounts);
  var config;
  before('setup contract', async () => {
    testPassenger = accounts[10];

    testFirstFlightID = "KUL123";
    testFirstCity = "Kuala Lumpur";
    testSecondFlightID = "LHR456";
    testSecondCity = "Heathrow";

    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

    it(`(contract) Check App-Data connection`, async function () {

        let status = await config.flightSuretyData.checkIfAuthorized.call(config.flightSuretyApp.address);
        assert.equal(status, true, "App is authorized to call Data");

    });

    it(`(multiparty) has correct initial isOperational() value`, async function () {
        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        console.log('status: ', status);
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
    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try
        {
            await config.flightSurety.setTestingMode(true);
        }
        catch(e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true);

    });

    it('(airline) Owner is the first airline', async () => {

        let result = false;
        let count = 0;
        // ACT
        try {
            count = await config.flightSuretyData.getAirlineCounts.call();
            result = await config.flightSuretyData.isAirline.call(accounts[0]);
        }
        catch(e) {
            // console.log(e);
        }

        // ASSERT
        assert.equal(result, true, "Owner should be the first 'Airline' ");
        assert.equal(count, 1, "Owner should be the only 'Airline' available");

    });


    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        let newAirline = accounts[2];

        // ACT
        try {
            await config.flightSuretyData.registerAirline.sendTransaction(newAirline, "second  airline", {from: accounts[0]});
        }
        catch(e) {
            // console.log(e);
        }

        let result = await config.flightSuretyData.isAirline.call(newAirline);

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });


    it("(airline) can register up to 4 Airlines using registerAirline() if it is funded ", async () => {

        let funds = await config.flightSuretyData.MIN_FUNDS.call();
        // ACT
        try {
            await config.flightSuretyData.fund({from: accounts[0], value: funds});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[2], "second airline", {from: accounts[0]});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[3], "third airline", {from: accounts[0]});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[4], "fourth airline", {from: accounts[0]});
        }
        catch(e) {
            console.log(e);
        }

        let result = await config.flightSuretyData.isAirline.call(accounts[4]);
        let count = await config.flightSuretyData.getAirlineCounts.call();

        // ASSERT
        assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");
        assert.equal(count.toString(), 4, "There should only be 4 airlines together");
    });

    it("(airline) can't register an Airline since at least 50% votes needed after 5 airlines upwards", async () => {

        let funds = await config.flightSuretyData.MIN_FUNDS.call();
        // ACT
        try {
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[5], "second airline", {from: accounts[0]});
        }
        catch(e) {
            // console.log(e);
        }

        let result = await config.flightSuretyData.isAirline.call(accounts[5]);
        let count = await config.flightSuretyData.getAirlineCounts.call();

        // ASSERT
        assert.equal(result, false, "5th Airline can't be registered without the voting");
        assert.equal(count.toString(), 4, "There should only be 4 airlines together");
    });

    it("(airline) after at least 50% votes to register an Airline using registerAirline() on 5 airlines upwards", async () => {

        let funds = await config.flightSuretyData.MIN_FUNDS.call();
        // ACT
        let votes;
        let result;
        let count;

        try {
            await config.flightSuretyData.fund({from: accounts[2], value: funds});
            await config.flightSuretyData.fund({from: accounts[3], value: funds});

            // we already have 4 airlines, so we need at least 2 votes
            await config.flightSuretyData.vote.sendTransaction(accounts[5], {from: accounts[2]});
            await config.flightSuretyData.vote.sendTransaction(accounts[5], {from: accounts[3]});

            votes =  await config.flightSuretyData.getVotes.call(accounts[5]);
            result = await config.flightSuretyData.isAirline.call(accounts[5]);
            count =  await config.flightSuretyData.getAirlineCounts.call();

            await config.flightSuretyData.registerAirline.sendTransaction(accounts[5], "second airline", {from: accounts[0]});
        }
        catch(e) {
            console.log(e);
        }

        result = await config.flightSuretyData.isAirline.call(accounts[5]);
        count  = await config.flightSuretyData.getAirlineCounts.call();

        // ASSERT
        assert.equal(result, true, "5th Airline can be registered after the voting");
        assert.equal(count.toString(), 5, "There should only be 4 airlines together");
    });


    it("(airline) can register new flights", async () => {
        // ACT
        try {
            await config.flightSuretyApp.registerFlight(testFirstFlightID,testFirstCity , Math.floor(Date.now() / 1000), {from: config.firstAirline});
            await config.flightSuretyApp.registerFlight(testSecondFlightID,testSecondCity , Math.floor(Date.now() / 1000), {from: config.firstAirline});
        }
        catch(e) {
            console.log(e);
        }
    });

    it("(passenger) can pay as high as 1 eth worth of insurance", async () => {
        //ARRANGE
        const max_insurance = await config.flightSuretyData.MAX_INSURANCE_LIMIT.call();
        const insurance = web3.utils.toWei('2', 'ether');
        const balanceBefore = await web3.eth.getBalance(testPassenger);

        // ACT
        try {
            await config.flightSuretyData.buy(testFirstFlightID, {from: testPassenger, value: insurance, gasPrice: 0});
        }
        catch(e) {
            console.log(e);
        }
        const balanceDiff = balanceBefore - await web3.eth.getBalance(testPassenger);

        // ASSERT
        assert.equal(balanceDiff.toString(), max_insurance.toString() , "only max amount are transferred from passenger's account");
    });

    it("(passenger) can buy multiple insurance from different flights", async () => {
        //ARRANGE
        const max_insurance = await config.flightSuretyData.MAX_INSURANCE_LIMIT.call();
        const insurance = web3.utils.toWei('2', 'ether');
        const balanceBefore = await web3.eth.getBalance(testPassenger);

        // ACT
        try {
            await config.flightSuretyData.buy(testSecondFlightID, {from: testPassenger, value: insurance, gasPrice: 0});
        }
        catch(e) {
            console.log(e);
        }
        const balanceDiff = balanceBefore - await web3.eth.getBalance(testPassenger);

        // ASSERT
        assert.equal(balanceDiff.toString(), max_insurance.toString() , "only max amount are transferred from passenger's account");
    });

    it("(passenger) receives 1.5x credit if flight is delayed", async () => {
        //ARRANGE
        let insurance, credit;

        // ACT
        try {
            insurance = await config.flightSuretyData.getInsurance.call(testFirstFlightID, testPassenger);
            await config.flightSuretyData.creditInsurees(testFirstFlightID, testPassenger);
            // await config.flightSuretyData.creditInsurees(testFirstFlightID);
            credit = await config.flightSuretyData.getCredit.call(testFirstFlightID, testPassenger);

        }
        catch(e) {
            console.log(e);
        }

        assert.equal(credit, insurance*1.5, "passenger would be payed 1.5x the insurance they paid");
    });

    it("(passenger) can withdraw the credit if the flight is late", async () => {
        //ARRANGE
        let paidAmount;
        let initialCredit;
        let finalCredit;
        let initialBalance;
        let finalBalance = 999; // use random number just to test
        let finalInsurance = 999 ; // use random number just to test

        // ACT
        try {
             initialCredit = await config.flightSuretyData.getCredit.call(testFirstFlightID, testPassenger);
             initialBalance = await web3.eth.getBalance(testPassenger);

             await config.flightSuretyData.pay(testFirstFlightID, {from: testPassenger});

             finalBalance = await web3.eth.getBalance(testPassenger);
             finalCredit = await config.flightSuretyData.getCredit.call(testFirstFlightID, testPassenger);
             finalInsurance = await config.flightSuretyData.getInsurance.call(testFirstFlightID, testPassenger);
        }
        catch(e) {
            console.log(e);
        }

        assert.equal(finalInsurance.toString(), 0, "final insurance should be 0");
    });

});
