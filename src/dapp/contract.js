import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        // this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.appAddress = config.appAddress;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            // we need to fund the owner so that it can take part with the contract
            this.fund(this.owner,0.1);
            console.log("Owner: " + this.owner);
            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }
            this.updateDataLists();
            callback();
        });
    }

    updateDataLists(){

        var funded_airline = document.getElementById('funded-airline');
        this.airlines.forEach(function(item){
            var option = document.createElement('option');
            option.value = item;
            funded_airline.appendChild(option);
        });
    }
    async registerAirline(airline, name, callback){
        let self = this;

        let payload = {
            airlineAddress: airline,
            name: name, 
            sender: self.owner
        }

        console.log("payload.airlineAddress:", payload.airlineAddress);
        console.log("payload.name:", payload.name);
        console.log("payload.sender:", payload.sender);
        console.log("Owner: " + this.owner);
        console.log("appAddress: " + this.appAddress);

            self.flightSuretyApp.methods
            .registerAirline(payload.airlineAddress, payload.name)
            .send({from: this.owner, gas: 5000000, gasPrice: 20000000}, (error, result) => {
                console.log(error);

                self.airlines.push(payload.airlineAddress);
                for(let i = 0; i < self.airlines.length; i++)
                {
                    console.log( (i+1) + ".th airline " + self.airlines[i]);
                }

                if (error)
                {
                    console.log(error);
                    callback(error,payload);
                }
                else
                {
                    this.updateDataLists();
                    self.flightSuretyApp.methods.getAirlineCounts().call({from:this.owner}, (error, result) => {
                        console.log("Airline Count: " + result);
                    });
                    callback(error,payload);
                }
            });


    }

    async fund(airline, fund, callback){
        let self = this;
        let fund_wei = this.web3.utils.toWei(fund.toString(), "ether");

        let payload = {
            airlineAddress: airline,
            fund: fund_wei,
            sum: -10
        }

            self.flightSuretyApp.methods
            .fund()
            .send({from: payload.airlineAddress, value: payload.fund, gas: 5000000, gasPrice: 20000000}, (error, result) => {

                if (error)
                {
                    console.log("fund error " +  error);
                    callback(error,payload);
                }
                else
                {
                    self.flightSuretyApp.methods
                    .getFunds()
                    .call({from: payload.airlineAddress}, (error, result) => {
                        payload.sum = result;
                        console.log("Sum Fund: " + payload.sum);
                    });
                    callback(error,payload);
                }
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
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}