var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "pull outdoor mind leg clap drift venture relax arrive charge genuine slot";
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
      // gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
