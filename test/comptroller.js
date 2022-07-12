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
        // let registered = await config.bsfComptroller.registerContract.call(_bsf_token, config.bsf20.address, {from: accounts[0]});
        // assert.equal(registered, true, "The BSF20 token contract was registered with the 'BSFComptroller'");

        let exists = await config.bsfComptroller.existsContract.call(_bsf_token);
        assert.equal(exists, true, "The BSF20 token contract does not exist.");
    });
});