const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const utils = require('./web3Utils');

const Joule = artifacts.require('./Joule.sol');

contract('Joule', accounts => {
    const OWNER = accounts[0];

    it('#1 register contract', async () => {
        const joule = await Joule.deployed();

    });
});