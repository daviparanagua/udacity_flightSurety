import "babel-polyfill";
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import flights from './flights.js';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
import cors from 'cors';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let owner = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

let oracles;

// Startup

const app = express();
app.use(cors());

async function start() {
  await initializeOracles();
  await startExpress();
  startOracleListeners();
}

async function initializeOracles() {
      let allAccounts = await web3.eth.getAccounts()
      let oracleAccounts = allAccounts.slice(20,40); 

      let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call()

      console.log(`Registering ${oracleAccounts.length} oracles...`)
        oracleAccounts.forEach(async address => {
          await flightSuretyApp.methods.registerOracle().send({
              from: address,
              value: fee,
              gas: 9999999
          })
          
          let indexes = await flightSuretyApp.methods.getMyIndexes().call({
                  from: address
              })

          let oracle = {indexes, address}

          oracles.push(oracle);
          // console.log(`Oracle Registered: ${oracle.indexes} points to ${oracle.address}`);
      });
}

function startExpress() {
  app.get('/api', (req, res) => {
      res.send({
        message: 'An API for use with your Dapp!'
      })
  })

  app.get('/api/flights', (req, res) => {
    res.send({
      status: 'OK',
      flights
    })
  })
}

start();

// Oracle listeners
function startOracleListeners() {

  oracles = [];

  flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, async function (error, event) {
    if (error) console.log(error)
    
    let eventData = event.returnValues;
    let statusCode = getRandomValue([0, 10, 20, 30, 40, 50]);

    oracles.filter(or => or.indexes.includes(eventData.index)).forEach(async oracle => {
      try {
        console.log(eventData.index, oracle.address);
        await flightSuretyApp.methods.submitOracleResponse(eventData.index, eventData.airline, eventData.flight, eventData.timestamp, statusCode).send({from: oracle.address, gas: 9999999});
      }
      catch (e) {
        console.error(e);
      }
      console.log(`Oracle response sent: ${oracle.address}, index(${eventData.index}) => ${statusCode}`)
    })
  });

  flightSuretyApp.events.FlightStatusInfo({
    fromBlock: 0
  }, async function (error, event) {
    if (error) console.log(error)
    
    let eventData = event.returnValues;
    console.log(`Flight status defined: airline: ${eventData.airline}, flight: ${eventData.flight}, timestamp: ${eventData.timestamp}, status: ${eventData.status}`);
  });

  flightSuretyApp.events.OracleRegistered({
    fromBlock: 0
  }, async function (error, event) {
    if (error) console.log(error)
    
    let eventData = event.returnValues;
    console.log(`Oracle Registered: address: ${eventData.oracleAddress}, indexes: ${eventData.indexes}`);
  });

  flightSuretyApp.events.InsureesCredited({
    fromBlock: 0
  }, async function (error, event) {
    if (error) console.log(error)
    
    let eventData = event.returnValues;
    console.log(`Insuree credited: airline: ${eventData.airline}, flight: ${eventData.flightID}`);
  });

  flightSuretyApp.events.LogMe({
    fromBlock: 0
  }, async function (error, event) {
    if (error) console.log(error)
    
    let eventData = event.returnValues;
    console.log(`Logged:`);
    console.log(eventData);
  });

}


function getRandomValue(array){
  return array[Math.floor(Math.random() * array.length)];
}

export default app;


