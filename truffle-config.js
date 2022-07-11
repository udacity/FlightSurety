var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "pilot cigar phone morning dumb evolve print profit hungry you potato clever";

module.exports = {
  //contracts_directory: "./contracts/airline",
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:9545/", 0, 50);
      },
      network_id: '*',
      gas: 6721975
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};