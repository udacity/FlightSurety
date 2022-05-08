var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "elegant spin road snake someone math slight pretty cup bleak stock region"; //exclusive-event


var NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker");

module.exports = {
  networks: {
    development: {
      // provider: function() {
      //   return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      // },
      host: "127.0.0.1",
      port: 8545,
      network_id: '*',
      websockets: true
      // gas: 9999999
      // gasLimit: 8000000
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
