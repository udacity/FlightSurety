const Test = require('../config/testConfig.js');
const BigNumber = require('bignumber.js');

const _bsf_surety_app = "bsf.surety.app";
const _bsf_surety_data = "bsf.surety.flight.data";

contract('BSF Comptroller Tests', async (accounts) => {

    let config;
    before('setup contract', async () => {
      config = await Test.Config(accounts);
      //await config.BsfComptroller.registerContract(_bsf_surety_app,config.flightSuretyApp.address);
    //   await config.BsfComptroller.registerContract(_bsf_surety_data,config.flightSuretyData.address);
        await config.flightSuretyApp.registerAirline
    });

    it(`Verify contracts registered with comptroller.`, async function () {

        let exists = await config.bsfComptroller.existsContract.call(_bsf_surety_app);
        assert.equal(exists, true, "The expected contract is not registered with comptroller.");
    });
});