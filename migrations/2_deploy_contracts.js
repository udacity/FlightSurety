const BsfComptroller = artifacts.require("BsfComptroller");
const Bsf20 = artifacts.require("BSF20");
const Bsf721 = artifacts.require("BSF721")
const AirlineData = artifacts.require("AirlineData");
const FlightData = artifacts.require("FlightData");
const FundData = artifacts.require("FundData");
const InsuranceData = artifacts.require("InsuranceData");
const PayoutData = artifacts.require("PayoutData");
const FlightSuretyApp = artifacts.require("FlightSuretyApp");

const fs = require('fs');

let _bsf_comptroller;

const _bsf_token = "bsf.token";
let _bsf_token_instance;
const _bsf_token_name = "Black Swan Foundry Token";
const _bsf_token_symbol = "BSFT";
const _bsf_token_decimals = 18;

let _bsf_airline_data_instance;
const _bsf_airline_data = "bsf.airline.data";

let _bsf_flight_data_instance;
const _bsf_flight_data = "bsf.flight.data";

let _bsf_fund_data_instance;
const _bsf_fund_data = "bsf.fund.data";

let _bsf_insurance_data_instance;
const _bsf_insurance_data = "bsf.insurance.data";

let _bsf_payout_instance;
const _bsf_payout_data = "bsf.payout.data";

let _bsf_flight_surety_app_instance;
const _bsf_flight_surety_app = "bsf.flight.surety.app";

module.exports = function(deployer, network, accounts) {

    deployer.deploy(BsfComptroller)
    .then((instance) => {
        _bsf_comptroller = instance;
        return deployer.deploy(Bsf20, _bsf_token_name, _bsf_token_symbol, _bsf_token_decimals, _bsf_comptroller.address, _bsf_token)
        .then(async (instance) => {
            _bsf_token_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_token, _bsf_token_instance.address);
            return deployer.deploy(AirlineData, _bsf_comptroller.address, _bsf_airline_data);
        }).then(async(instance) => {
            _bsf_airline_data_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_airline_data, _bsf_airline_data_instance.address);
            return deployer.deploy(FlightData, _bsf_comptroller.address, _bsf_flight_data);
        }).then(async(instance) => {
            _bsf_flight_data_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_flight_data, _bsf_flight_data_instance.address);
            return deployer.deploy(FundData, _bsf_comptroller.address, _bsf_fund_data);
        }).then(async(instance) => {
            _bsf_fund_data_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_fund_data, _bsf_fund_data_instance.address);
            return deployer.deploy(InsuranceData, _bsf_comptroller.address, _bsf_insurance_data);
        }).then(async(instance) => {
            _bsf_insurance_data_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_insurance_data, _bsf_insurance_data_instance.address);
            return deployer.deploy(PayoutData, _bsf_comptroller.address, _bsf_payout_data);
        }).then(async(instance) => {
            _bsf_payout_data_instance = instance;
            await _bsf_comptroller.registerContract(_bsf_payout_data, _bsf_payout_data_instance.address);
            return deployer.deploy(FlightSuretyApp, _bsf_comptroller.address, _bsf_flight_surety_app);
        }).then(async(instance) => {
            _bsf_flight_surety_app_instance = instance;
            let config = {
                localhost: {
                    url: 'http://localhost:9545',
                    airlineData: _bsf_airline_data_instance.address,
                    flightData: _bsf_flight_data_instance.address,
                    fundData: _bsf_fund_data_instance.address,
                    insuranceData: _bsf_insurance_data_instance.address,
                    payoutData: _bsf_payout_data_instance.address,
                    appAddress: _bsf_flight_surety_app_instance.address,
                    comptrollerAddress: _bsf_comptroller.address,
                    bsf20: _bsf_token_instance.address
                }
            };
            fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
            fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
        });
    });
}