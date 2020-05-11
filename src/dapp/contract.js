import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from "../../build/contracts/FlightSuretyData.json";
import Config from './config.json';
import Web3 from 'web3';

let config = null;
export default class Contract {
    constructor(network, callback) {

        config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.flights = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
            console.log("config.appaddress: "+config.appAddress);

            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 4) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            console.log("Setting app contract")
            let self = this;
            self.flightSuretyData.methods
            .authorizeCaller(config.appAddress)
            .send({ from: self.owner}, (error, result) => {
                console.log(error,result);
            });

            self.flightSuretyData.methods.fund().send({
                from: self.airlines[0],
                value: self.web3.utils.toWei('10', "ether"),
                gas: 3000000
              }, (error, result) => {
                console.log(error,result);
            })

            this.flights[0] = {flight: 'CA888', address: this.airlines[0], timestamp: null};

            callback();
        });
    }

    registerFlight(flight, callback) {
        let self = this;
        let payload = {
            flight: flight.flight,
            airline: flight.address,
            timestamp: flight.timestamp
        } 
        console.log(payload);
        self.flightSuretyApp.methods.registerFlight(payload.flight, payload.timestamp)
        .send({ from: payload.airline, gas: 3000000}, (error, result) => {
            console.log(error, result);
            callback(error, result);
        });
    }

    buy(flight, premium, callback) {
        let self = this;
        let payload = {
            flight: flight.flight,
            airline: flight.address,
            timestamp: flight.timestamp
        } 
        console.log(self.passengers[0]);
        console.log(payload);
        self.flightSuretyApp.methods
            .buy(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.passengers[0], value: premium, gas: 3000000}, (error, result) => {
                console.log(error, result);
                callback(error, result);
            });
    }

    getBalance(callback) {
        let self = this;
        self.flightSuretyApp.methods
             .getBalance()
             .call({from: self.passengers[0], gas: 3000000}, (error, result) => {
                console.log(error, result);
                callback(error, result);
            });
    }

    withdraw(callback) {
        let self = this;
        self.flightSuretyApp.methods
             .withdraw()
             .send({from: self.passengers[0], gas: 3000000}, (error, result) => {
                console.log(error, result);
                callback(error, result);
            });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            flight: flight.flight,
            airline: flight.address,
            timestamp: flight.timestamp
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}