require("dotenv").config();
var HDWalletProvider = require("@truffle/hdwallet-provider");
//var mnemonic = "pilot cigar phone morning dumb evolve print profit hungry you potato clever";

module.exports = {
  //contracts_directory: "./contracts/fund",
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(process.env.MNEMONIC, "http://127.0.0.1:9545/", 0, 50);
      },
      network_id: '*',
      gas: process.env.GAS
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};