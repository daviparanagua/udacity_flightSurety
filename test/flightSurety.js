
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const web3 = require('web3');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, 'Azul Airlines', {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyApp.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can fund itself, but only with enough ether', async () => {
    
    // ARRANGE
    let isAirline = await config.flightSuretyApp.isAirline.call(config.firstAirline); 
    assert.equal(isAirline, true, "Is already airline");

    let isFunded = await config.flightSuretyApp.isFundedAirline.call(config.firstAirline); 
    assert.equal(isFunded, false, "Not funded yet");

    let reverted = false

     // ACT
     try {
      await config.flightSuretyApp.addFunds({from: config.firstAirline, value: web3.utils.toWei('1', 'gwei')});
      }
      catch(e) {
        reverted = true;
      }

      isAirline = await config.flightSuretyApp.isAirline.call(config.firstAirline); 
      assert.equal(isAirline, true, "Still airline");

      let isNowFunded = await config.flightSuretyApp.isFundedAirline.call(config.firstAirline); 
      assert.equal(isNowFunded, false, "No good. Few ether");

      // ACT
      reverted = false;
      
      try {
          await config.flightSuretyApp.addFunds({from: config.firstAirline, value: web3.utils.toWei('10', 'ether')});
      }
      catch(e) {
        reverted = true;
        console.error(e);
      }

      isAirline = await config.flightSuretyApp.isAirline.call(config.firstAirline); 
      assert.equal(isAirline, true, "Still airline");

      isNowFunded = await config.flightSuretyApp.isFundedAirline.call(config.firstAirline); 
      assert.equal(isNowFunded, true, "Is now funded");
      assert.equal(reverted, false, "Transaction must not revert");

  });

  it('(airline) cannot fund itself if its not an airline', async () => {
    
    // ARRANGE
    let notAirline = accounts[3];

    let reverted = false;
    // ACT
    try {
      await config.flightSuretyApp.addFunds({from: notAirline, value: web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      reverted = true;
    }
    let isAirline = await config.flightSuretyApp.isAirline.call(notAirline);
    let isFundedAirline = await config.flightSuretyApp.isFundedAirline.call(notAirline);

    // ASSERT
    assert.equal(isAirline, false, "Airline should not be able to register itself if it's not an airline");
    assert.equal(isFundedAirline, false, "Airline should not be able to fund itself if it's not an airline");
    assert.equal(reverted, true, "Transaction must revert");

  });

  it('(airline) can register an Airline using registerAirline() once funded, up to 4 accounts', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let reverted = false;

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, 'Blue2 Airlines', {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(newAirline3, 'Red3 Airlines', {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(newAirline4, 'Green4 Airlines', {from: config.firstAirline});
    }
    catch(e) {
      reverted = true;
    }
    let result2 = await config.flightSuretyApp.isAirline.call(newAirline);
    let result3 = await config.flightSuretyApp.isAirline.call(newAirline3);
    let result4 = await config.flightSuretyApp.isAirline.call(newAirline4);

    // ASSERT
    assert.equal(result2, true, "Airline should be able to register another airline (2) if it has provided funding");
    assert.equal(result3, true, "Airline should be able to register another airline (3) if it has provided funding");
    assert.equal(result4, true, "Airline should be able to register another airline (4) if it has provided funding");
    assert.equal(reverted, false, "Transaction must not revert");

  });

  it('(airline) can register fifth airline by multi-party consensus only', async () => {

    // ARRANGE
    let newAirline = accounts[5];
    let approver = accounts[2];
    let reverted = false;

    // ACT
    try {
      await config.flightSuretyApp.registerAirline(newAirline, 'Yellow5 Airlines', {from: config.firstAirline});
    }
    catch(e) {
      reverted = true
    }
    let result = await config.flightSuretyApp.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline after the fourth");
    assert.equal(reverted, false, "Transaction must not revert");

    // ACT

    await config.flightSuretyApp.addFunds({from: approver, value: web3.utils.toWei('10', 'ether')}); // Fund itself before approval

    try {
      await config.flightSuretyApp.registerAirline(newAirline, 'Yellow5 Airlines', {from: approver});
    }
    catch(e) {
      reverted = true
    }

    result = await config.flightSuretyApp.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline be an airline after multi-party consensus");
    assert.equal(reverted, false, "Transaction must not revert");

  });
 
  it('(airline) multi-party airline can fund itself', async () => {

    // ARRANGE
    let newAirline = accounts[5];
    let reverted = false;

    let result = await config.flightSuretyApp.isFundedAirline.call(newAirline);
    assert.equal(result, false, "Airline should not be funded in the beggining");


    // ACT
    try {
      await config.flightSuretyApp.addFunds({from: newAirline, value: web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      reverted = true
    }
    result = await config.flightSuretyApp.isFundedAirline.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline should be funded after funding itself");
    assert.equal(reverted, false, "Transaction must not revert");
  });
 

});
