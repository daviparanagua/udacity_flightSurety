import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.events = this.flightSuretyApp.events;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.firstAirline = '0xf17f52151EbEF6C7334FAD080c5704D77216b732';
            this.owner = accts[0];
            this.flightSuretyData.methods.authorizeCaller(this.flightSuretyApp._address).send({from: this.owner});

            let counter = 1;

            this.flightSuretyApp.methods.isFundedAirline(this.firstAirline).call({from: this.firstAirline}, (err, res) => {
                if(res) {
                    console.log("airline already funded");
                    callback();
                }
                else {
                    console.log("funding airline");
                    this.flightSuretyApp.methods.addFunds().send({from: this.firstAirline, value: Web3.utils.toWei('10', 'ether')}, (err, res) => {
                        callback();
                    })
                }
            })

            this.airlines.push(this.firstAirline);

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
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

    buyInsurance(flightId, callback) {
        let self = this;
        console.log(`Buying insurance for ${flightId} from ${self.passengers[0]}`)
        self.flightSuretyApp.methods
             .buyInsurance(flightId, self.airlines[0]).send({ from: self.passengers[0], value: this.web3.utils.toWei('1', 'ether'), gas: 9999999}, callback);
     }

    getInsurance(flightId, callback) {
    let self = this;
    self.flightSuretyApp.methods
            .getInsurance(flightId).call({ from: self.passengers[0]}, callback);
    }

    getWithdrawBalance(callback) {
        let self = this;
        self.flightSuretyApp.methods
                .getMyBalance().call({ from: self.passengers[0]}, callback);
    }

    withdrawFunds(callback) {
        let self = this;
        self.flightSuretyApp.methods
             .withdrawFunds().send({ from: self.passengers[0]}, callback);
    }

    getMyBalance(callback) {
        let self = this;
        this.web3.eth.getBalance(self.passengers[0], callback);
    }
}