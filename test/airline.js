const Test = require('../config/testConfig.js');
const BigNumber = require('bignumber.js');

const _bsf_surety_app = "bsf.surety.app";
const _bsf_surety_data = "bsf.surety.flight.data";

contract('BSF Comptroller Tests', async (accounts) => {

    let config;
    before('setup contract', async () => {
      config = await Test.Config(accounts);
    });

    // it(`Verify 'AirlineData' contract registered with comptroller.`, async function () {

    // });
});