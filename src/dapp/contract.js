import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.appAddress = config.appAddress;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            console.log("Owner: " + this.owner);
            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
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

        // await this.web3.eth.getAccounts((error, accts) => {
        //     payload.sender = accts[0];
        // });

        console.log("Owner: " + this.owner);
        console.log("appAddress: " + this.appAddress);
        self.flightSuretyApp.methods
            .registerAirline(payload.airlineAddress, payload.name)
            .send({from: this.owner, gas: 5000000, gasPrice: 20000000}, (error, result) => {
                console.log(error);
                // if (error)
                // {
                //     console.log(error);
                //     callback(error,payload);
                // }
                // else
                // {
                //     self.flightSuretyData.methods
                //     .isRegistered(payload.airline)
                //     .call({from: payload.sender}, (error, result) =>
                //     {
                //         if(error)
                //         {
                //             payload.message = 'Cannot register airlines, maybe not enough votes available';
                //             callback(error, payload);
                //         }
                //         else 
                //         {
                //             payload.message = 'Airline ' + payload.name + ' from ' + payload.airline + ' registered';
                //             callback(error, payload)
                //         }

                //     });
                // }
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