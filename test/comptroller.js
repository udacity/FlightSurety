const Test = require('../config/testConfig.js');
const BigNumber = require('bignumber.js');

const _bsf_surety_app = "bsf.surety.app";
const _bsf_surety_data = "bsf.surety.data";

contract('BSF Comptroller Tests', async (accounts) => {

    let config;
    before('setup contract', async () => {
      config = await Test.Config(accounts);
    });

    it(`Verify contracts registered with comptroller.`, async function () {
        config = await Test.Config(accounts);
        let exists = await config.bsfComptroller.existsContract.call(_bsf_surety_app);
        assert.equal(exists, true, "The expected contract is not registered with comptroller.");
    });
});