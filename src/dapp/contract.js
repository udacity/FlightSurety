import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress, { data: '0x8473ba69863B08BC0995D516d84112F73DEC3b08'});
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress, { data: config.dataAddress });
        this.appAdress = config.appAddress;
        this.initialize(callback);

        this.owner = null;
        this.airlines = [];
        this.airlinesNames = [];
        this.flights = [];
        this.AirlineFlights = {};
        this.passengers = [];
    }

    getLength(){
        console.log('NUMBER OF ACCOUNT ' + this.web3.eth.accounts.length);
    }

    getBalance(account){
        this.web3.eth.getBalance(account, (error, balance) => {
            if (error) {
                console.error(error);
            } else {
                console.log(`Account ${account} has a balance of ${this.web3.utils.fromWei(balance, "ether")} Ether`);
            }
        });
    }

    async initialize(callback) {
        // this.web3.eth.getAccounts((error, accts) => {
            const getAccounts = () => {
                return new Promise((resolve, reject) => {
                  this.web3.eth.getAccounts((error, accts) => {
                    if (error) {
                      reject(error);
                    } else {
                      resolve(accts);
                    }
                  });
                });
              };
            
            try {
                const accts = await getAccounts();
            
            this.owner = accts[0];
            console.log('Owner address is : ' + this.owner);
            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }
            this.airlinesNames[this.airlines[0]] = "Ryanair";
            this.airlinesNames[this.airlines[1]] = "Easyjet";
            this.airlinesNames[this.airlines[2]] = "Lufthansa";

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            let numFlight = 10;
            while(this.flights.length < 3) {
                numFlight++;
                this.flights.push("R" + numFlight.toString() + "AIR")
            }
            this.AirlineFlights[this.airlinesNames[this.airlines[0]]] = [this.flights[0], this.flights[1], this.flights[2]];
            numFlight = 23;
            while(this.flights.length < 6) {
                numFlight++;
                this.flights.push("E" + numFlight.toString() + "FLY")
            }
            this.AirlineFlights[this.airlinesNames[this.airlines[1]]] = [this.flights[3], this.flights[4], this.flights[5]];
            numFlight = 36;
            while(this.flights.length < 9) {
                numFlight++;
                this.flights.push("L" + numFlight.toString() + "SKY")
            }
            this.AirlineFlights[this.airlinesNames[this.airlines[2]]] = [this.flights[6], this.flights[7], this.flights[8]];

            // console.log('App address is ' + this.appAdress)

            await this.flightSuretyData.methods.authorizeCaller(this.appAdress).send({ from: this.owner})
                .on('transactionHash', function(hash){
                    // console.log('Transaction hash:', hash);
                })
                .on('receipt', function(receipt){
                    // console.log('Transaction receipt auth caller :', receipt);
                    console.log('App authorized.')
                })
                .on('error', function(error){
                    console.log('Error:', error);
                });

            // for initialization, to register airline 0 only should be enough
            // but it has been demonstrated in truffle test the functions works well
            // so as simplification, the airlines will be registered here rather than in the app
            for(let iAirline = 0 ; iAirline < 3 ; iAirline++){
                let ifRegistered = await this.flightSuretyData.methods.isAirlineRegistered(this.airlines[iAirline]).call();
                if (!ifRegistered){
                    await this.initializeAirline(iAirline);
                }else{
                    console.log('Airline ' + this.airlinesNames[this.airlines[iAirline]] + ' is already registered.')
                }
                let ifFunded = await this.flightSuretyData.methods.hasGivenFund(this.airlines[iAirline]).call();
                if (!ifFunded){
                    this.fundContract(iAirline);
                }else{
                    console.log('Airline ' + this.airlinesNames[this.airlines[iAirline]] + ' already funded the contract.')
                }
            }

            // this.getBalance(this.airlines[0]);
            for(let iAirline = 0 ; iAirline < 3 ; iAirline++){
                for(let iFlight = 0 ; iFlight < 3 ; iFlight++){
                    // let iAirline = 0;
                    // let iFlight = 0;
                    try{
                        await this.registerAirlineFlight(iAirline,iFlight);
                        await this.flightSuretyApp.methods.isFlightRegistered(this.AirlineFlights[this.airlinesNames[this.airlines[iAirline]]][iFlight]).call(function(error, result) {
                            console.log('Flight is registered : ', result);
                        });
                    }catch(e){
                        console.log('Error for flight registration is : ' + e)
                    }
                }
            }
            // //http://localhost:8000/#

            callback();
        // });
        } catch (error) {
            console.error('Error at top level :', error);
        }
    }

    isAuth(){
        this.flightSuretyData.methods.isAppAuthorized(this.appAdress).call(function(error, result) {
            if (error) {
                console.log('Error:', error);
            } else {
                console.log('Output appIsAuthorised : ', result);
            }
            })
    }

    async initializeAirline(airlineNumber){
        await this.flightSuretyApp.methods.registerAirline(this.airlines[airlineNumber], this.airlinesNames[this.airlines[airlineNumber]]).send({ 
            "from": this.owner,  
            "gas": 4712388,
            "gasPrice": 100000000000
        }) //.on('transactionHash', function(hash){console.log('Transaction hash:', hash);})
        .on('receipt', function(receipt){
            // console.log('Transaction receipt reg airl:', receipt);
        })
        .on('error', function(error){
            console.log('Error :', error);
        });
        this.flightSuretyData.methods.isAirlineRegistered(this.airlines[airlineNumber]).call(function(error, result) {
            if (error) {console.log('Error check :', error);} else {console.log('Airline ' + airlineNumber.toString() + ' is registered :', result);}});
    }

    async fundContract(airlineNumber){
        // fund the contract
        await this.flightSuretyData.methods.fund().send({from: this.airlines[airlineNumber], value: Web3.utils.toWei('10', 'ether')}).on('receipt', function(receipt){
            // console.log('Transaction receipt funding :', receipt)
            ;})
        .on('error', function(error){
            console.log('Error :', error);
        });
        this.flightSuretyData.methods.hasGivenFund(this.airlines[airlineNumber]).call(function(error, result) {
            if (error) {console.log('Error check :', error);} else {
            console.log('Airline ' + airlineNumber.toString() + ' has funded contract : ', result);
            }
        });
    }

    async registerAirlineFlight(airlineNumber,flightNumber){
        let timestamp = Math.floor(Date.now() / 1000);
        // this.AirlineFlights[this.airlinesNames[this.airlines[airlineNumber]]][flightNumber]
        console.log('flight is ' + this.AirlineFlights[this.airlinesNames[this.airlines[airlineNumber]]][flightNumber])
        await this.flightSuretyApp.methods.registerFlight(this.AirlineFlights[this.airlinesNames[this.airlines[airlineNumber]]][flightNumber], 0, timestamp).send({ from: this.airlines[airlineNumber],
            "gas": 4712388,
            "gasPrice": 100000000000 });
    }

    pay(msgSender){
        let self = this;
        self.flightSuretyData.methods.pay().call({ from: msgSender});
    }

    hasGivenFund(addrAirline){
        this.flightSuretyData.methods.hasGivenFund(addrAirline).call(function(error, result) {
            if (error) {
              console.log('Error check :', error);
            } else {
              console.log('Airline has funded contract :', result);
            }
        });
    }

    displayCreditAmount(msgSender){
        let self = this;
        self.flightSuretyData.methods.displayInsureeCreditAmount().call({ from: msgSender});
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    async insureFlight(airlineAdr, flight, msgSender, priceInsurance, callback) {
        let self = this;
        let priceValue = priceInsurance.toString();
        await self.flightSuretyData.methods
            .buy(airlineAdr, flight)
            .send({ from: msgSender, value: Web3.utils.toWei(priceValue, 'ether'),"gas": 4712388,
            "gasPrice": 100000000000 }, callback);
     }

    fetchFlightStatus(airlineFl,flight,timestampFlight, callback) {
        let self = this;
        let payload = {
            airline: airlineFl,
            flight: flight,
            timestamp: timestampFlight
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    async maxInsurancePrice(){
        const price = await this.flightSuretyData.methods.getMaxInsurancePrice().call({ from: this.owner });
        // console.log("Price max is ", price);
        return price;
    }

    async custInsuredOrNot(flight, customerAddress){
        const yesNo = await this.flightSuretyData.methods.IsCustomerInsured(flight).call({ from: customerAddress});
        return yesNo
    }


}