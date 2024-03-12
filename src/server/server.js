const FlightSuretyApp = require('../../build/contracts/FlightSuretyApp.json');
const Config = require('./config.json');
const Web3 = require('web3');
const express = require('express');
const path = require('path');

const config = Config['localhost'];
const options = {
  // Enable auto reconnection
  reconnect: {
      auto: true,
      delay: 50000, // in milliseconds
      maxAttempts: 10,
      onTimeout: false
  }
};
let web3Provider = new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws'), options);
const web3 = new Web3(web3Provider);
const flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress, { data: config.dataAddress });

const app = express();
const server = app.listen(3000, () => {
  const port = server.address().port;
  console.log(`Server is running on port ${port}`);
});

app.get('/api', (req, res) => {
  const filePath = path.join(__dirname, 'index.html');
  res.sendFile(filePath);
});

module.exports = app;