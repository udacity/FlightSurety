var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "grace orphan drink execute picnic ordinary festival rare net below rose attitude";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
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