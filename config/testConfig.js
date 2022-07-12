
const BsfComptroller = artifacts.require("BsfComptroller");
const Bsf20 = artifacts.require("BSF20");
const Bsf721 = artifacts.require("BSF721")
const AirlineData = artifacts.require("AirlineData");
const FlightData = artifacts.require("FlightData");
const FundData = artifacts.require("FundData");
const InsuranceData = artifacts.require("InsuranceData");
const PayoutData = artifacts.require("PayoutData");
const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const BigNumber = require('bignumber.js');

const Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    const testAddresses = [
        process.env.ACCOUNT1,
        process.env.ACCOUNT2,
        process.env.ACCOUNT3,
        process.env.ACCOUNT4,
        process.env.ACCOUNT5,
        process.env.ACCOUNT6,
        process.env.ACCOUNT7,
        process.env.ACCOUNT8,
        process.env.ACCOUNT9,
        process.env.ACCOUNT10,
        //"0x0f47d5a13e9a46fa3e0ae08acdca8423dbff15a6",
        //"0x69bbf76cebe5bdcd7548d30e8eadf8d6a3b6189d",
        //"0xc8f4639ebe6cdea17d1c5c0a2d5b99bf3cec77e0",
        //"0xe643809c5f559a07ad023bda5cc2aec4770ee244",
        //"0x20e111816bf372422d3b4ed48ec5173846f06830",
        //"0x2370ec37739af989cc9f21850911db899a4ff486",
        //"0x6ab9384ad4571dcd28e8cc3bfdf2a76996629bdf",
        //"0xc427188e05352d1c5bf9235a568f8112e7d35263",
        //"0x56625abdd471888e93225a57aac02de94c6aa276"
    ];


    const owner = accounts[0];
    const firstAirline = accounts[1];
    const secondAirline = accounts[2];
    const thirdAirline = accounts[3];

    const _bsf_comptroller = "bsf.comptroller";
    const _bsf_token = "bsf.token";
    const _bsf_token_name = "Black Swan Foundry Token";
    const _bsf_token_symbol = "BSFT";
    const _bsf_token_decimals = 18;

    const _bsf_airline_data = "bsf.airline.data";
    const _bsf_flight_data = "bsf.flight.data";
    const _bsf_fund_data = "bsf.fund.data";
    const _bsf_insurance_data = "bsf.insurance.data";
    const _bsf_payout_data = "bsf.payout.data";
    const _bsf_flight_surety_app = "bsf.flight.surety.app";

    const bsfComptroller = await BsfComptroller.new(_bsf_comptroller,{from: owner});
    console.log(`[Comptroller]: ${bsfComptroller.address}`);

    const bsf20 = await Bsf20.new(_bsf_token_name, _bsf_token_symbol, _bsf_token_decimals, bsfComptroller.address, _bsf_token, {from:owner});
    console.log(`[BSF20]: ${bsf20.address}`);
    const tokenRegistered = await bsfComptroller.registerContract.call(_bsf_token, bsf20.address, {from: owner});
    console.log(`[Comptroller Registration]: ${tokenRegistered}`);

    const airlineData = await AirlineData.new(bsfComptroller.address, _bsf_airline_data, {from: owner});
    console.log(`[AirlineData]: ${airlineData.address}`);
    const airlineDataRegistered = await bsfComptroller.registerContract.call(_bsf_airline_data, airlineData.address, {from: owner});
    console.log(`[Comptroller Registration]: ${airlineDataRegistered}`);

    const flightData = await FlightData.new(bsfComptroller.address, _bsf_flight_data, {from: owner});
    console.log(`[FlightData]: ${flightData.address}`);
    const flightDataRegistered = await bsfComptroller.registerContract.call(_bsf_flight_data, flightData.address, {from: owner});
    console.log(`[Comptroller Registration]: ${flightDataRegistered}`);

    const fundData = await FundData.new(bsfComptroller.address, _bsf_fund_data, {from: owner});
    console.log(`[FundData]: ${fundData.address}`);
    const fundDataRegistered = await bsfComptroller.registerContract.call(_bsf_fund_data, fundData.address, {from: owner});
    console.log(`[Comptroller Registration]: ${fundDataRegistered}`);

    const insuranceData = await InsuranceData.new(bsfComptroller.address, _bsf_insurance_data, {from: owner});
    console.log(`[InsuranceData]: ${insuranceData.address}`);
    const insuranceDataRegistered = await bsfComptroller.registerContract.call(_bsf_insurance_data, insuranceData.address, {from: owner});
    console.log(`[Comptroller Registration]: ${insuranceDataRegistered}`);

    const payoutData = await PayoutData.new(bsfComptroller.address, _bsf_payout_data, {from: owner});
    console.log(`[PayoutData]: ${payoutData.address}`);
    const payoutDataRegistered = await bsfComptroller.registerContract.call(_bsf_insurance_data, payoutData.address, {from: owner});
    console.log(`[Comptroller Registration]: ${payoutDataRegistered}`);

    const flightSuretyApp = await FlightSuretyApp.new(bsfComptroller.address, _bsf_flight_surety_app);
    console.log(`[FlightSuretyApp]: ${flightSuretyApp.address}`);
    const flightSuretyAppRegistered = await bsfComptroller.registerContract.call(_bsf_flight_surety_app, flightSuretyApp.address, {from: owner});
    console.log(`[Comptroller Registration]: ${flightSuretyAppRegistered}`);
    
    return {
        owner: owner,
        firstAirline: firstAirline,
        secondAirline: secondAirline,
        thirdAirline: thirdAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        bsfComptroller: bsfComptroller,
        bsf20: bsf20,
        flightSuretyApp: flightSuretyApp,
        airlineData: airlineData,
        flightData: flightData,
        fundData: fundData,
        insuranceData: insuranceData,
        payoutData: payoutData,
        
    }
}

module.exports = {
    Config: Config
};