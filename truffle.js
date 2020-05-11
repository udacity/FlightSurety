var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "cabin exist eye sock bone business connect baby napkin furnace purchase moment";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      network_id: '*'
    },

    develop: {
      accounts: 30,
    }
  },
  compilers: {
    solc: {
      version: "^0.6.0"
    }
  }
};