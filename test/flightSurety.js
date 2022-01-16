var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {
  //console.log(accounts);
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

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        let newAirline = accounts[2];

        // ACT
        try {
            await config.flightSuretyData.registerAirline(newAirline, {from: accounts[0]});
        }
        catch(e) {
            // console.log(e);
        }

        let result = await config.flightSuretyData.isAirline.call(newAirline);

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });


    it("(airline) can register up to 4 Airlines using registerAirline() if it is funded ", async () => {

        let funds = await config.flightSuretyData.getMinFund.call();
        // ACT
        try {
            await config.flightSuretyData.fund({from: accounts[0], value: funds});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[2], "second airline", {from: accounts[0]});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[3], "second airline", {from: accounts[0]});
            await config.flightSuretyData.registerAirline.sendTransaction(accounts[4], "second airline", {from: accounts[0]});
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

    it("(airline) needs at least 50% votes to register an Airline using registerAirline() on 5 airlines upwards", async () => {

        let funds = await config.flightSuretyData.getMinFund.call();
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

        let funds = await config.flightSuretyData.getMinFund.call();
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

            console.log("votes: " + votes.toString());
            console.log("airlines: " + count.toString());

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



    // it("(airline) needs at least 50% votes to register an Airline using registerAirline() after 4 airlines", async () => {

    //     let funds = await config.flightSuretyData.getMinFund.call();
    //     // ACT
    //     try {
    //         await config.flightSuretyData.fund({from: accounts[0], value: funds});
    //         await config.flightSuretyApp.registerAirline.sendTransaction(accounts[3], "third airline", {from: accounts[0]});
    //         await config.flightSuretyApp.registerAirline(accounts[4], "fourth airline", {from: accounts[0]});
    //         await config.flightSuretyApp.registerAirline(accounts[5], "fifth airline", {from: accounts[0]});
    //     }
    //     catch(e) {
    //         console.log(e);
    //     }
    //     let result = await config.flightSuretyData.isAirline.call(accounts[5]);
    //     let count = await config.flightSuretyData.getAirlineCounts.call();

    //     // ASSERT
    //     assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");
    //     assert.equal(count.toString(), 2, "There should only be 2 airlines together");
    // });

});
