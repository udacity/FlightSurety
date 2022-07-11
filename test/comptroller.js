const Test = require('../config/testConfig.js');
const BigNumber = require('bignumber.js');

const _bsf_token = "bsf.token";
const _bsf_surety_app = "bsf.surety.app";
const _bsf_surety_data = "bsf.surety.data";

contract('BSF Comptroller Tests', async (accounts, network) => {

    let config;
    before('Setup Test Configuration', async () => {
      config = await Test.Config(accounts);
    });

    it(`Register Token with Comptroller`, async function () {
        //let registered = config.bsfComptroller.registerContract.call(_bsf_token, config.bsf20.address, {from: accounts[0]});
        let exists = config.bsfComptroller.existsContract.call(_bsf_token);
        assert.equals(exists, true, "The BSF20 token contract is not registered with comptroller.");
    });
});