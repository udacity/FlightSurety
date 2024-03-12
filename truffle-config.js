var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "scorpion person boring label type prepare sunset honey comic sort dream leg";
// ganache-cli --port 8545 --gasLimit 12000000 --accounts 50 --mnemonic 'candy maple cake sugar pudding cream honey rich smooth crumble sweet treat'

module.exports = {
  contracts_directory: './contracts',
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 9999999
    }
  },
  testnet: {
    networkCheckTimeout: 10000,
    timeoutBlocks: 200
  },
  "development": {
    accounts: 30,
    defaultEtherBalance: 1000,
  },
  compilers: {
    solc: {
      version: "0.8.0"
    }
  }
};