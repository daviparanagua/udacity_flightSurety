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

let oracles = [];

const app = express();
app.use(cors());

async function start() {
  await initializeOracles();
  startExpress();
}


async function initializeOracles() {
      let allAccounts = await web3.eth.getAccounts()
      let oracleAccounts = allAccounts.slice(20,40); 

      let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call()

      console.log(`Registering ${oracleAccounts.length} oracles...`)
        oracleAccounts.forEach(async account => {
          await flightSuretyApp.methods.registerOracle().send({
              from: account,
              value: fee,
              gas: 9999999
          })
          
          let indexes = await flightSuretyApp.methods.getMyIndexes().call({
                  from: account
              })

          let oracle = {indexes, account}

          oracles.push(oracle);
          console.log(`Oracle Registered: ${oracle.indexes} points to ${oracle.account}`);
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
export default app;


