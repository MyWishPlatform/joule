const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const utils = require('./web3Utils');
const BigNumber = require('bignumber.js');
chai.use(require("chai-bignumber")(BigNumber));

const JouleNative = artifacts.require("./Joule.sol");
const Joule = artifacts.require("./JouleBehindProxy.sol");
const Proxy = artifacts.require("./JouleProxy.sol");
const Storage = artifacts.require("./JouleStorage.sol");
const Vault = artifacts.require("./JouleVault.sol");
const Contract0kGas = artifacts.require("./Contract0kGas.sol");
const Contract100kGas = artifacts.require("./Contract100kGas.sol");
const Contract200kGas = artifacts.require("./Contract200kGas.sol");
const Contract300kGas = artifacts.require("./Contract300kGas.sol");
const Contract400kGas = artifacts.require("./Contract400kGas.sol");

const commonTest = require("./jouleCommon");

const SECOND = 1;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

let NOW, TOMORROW, DAY_AFTER_TOMORROW;

const initTime = (now) => {
    NOW = now;
    TOMORROW = now + DAY;
    DAY_AFTER_TOMORROW = TOMORROW + DAY;
};

initTime(new Date("2017-10-10T15:00:00Z").getTime() / 1000);

contract('Joule', accounts => {
    let snapshotId;

    beforeEach(async () => {
        // if (typeof snapshotId !== 'undefined') {
        //     await revert(snapshotId);
        // }
        snapshotId = (await snapshot()).result;
        const latestBlock = await utils.web3async(web3.eth, web3.eth.getBlock, 'latest');
        initTime(latestBlock.timestamp);
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    const createJoule = async () => {
        const vault = await Vault.new();
        const storage = await Storage.new();
        const joule = await JouleNative.new(vault.address, 0, 0, storage.address);
        await vault.setJoule(joule.address);
        await storage.giveAccess(joule.address);
        return joule;
    };

    commonTest.init(accounts, createJoule);
    commonTest.forEachTest(function (test) {
        it(test.name, test.test);
    });
});

contract('JouleProxy', accounts => {
    const OWNER = accounts[0];
    const SENDER = accounts[1];

    const addresses = accounts;

    const gasLimit1 = 99990;
    const gasLimit2 = 199965;
    const gasLimit3 = 299983;
    const gasLimit4 = 399958;

    const ETH = web3.toWei(BigNumber(1), 'ether');
    const GWEI = web3.toWei(BigNumber(1), 'gwei');
    const gasPrice1 = web3.toWei(2, 'gwei');
    const gasPrice2 = web3.toWei(3, 'gwei');
    const gasPrice3 = web3.toWei(4, 'gwei');
    const gasPrice4 = web3.toWei(5, 'gwei');

    const threeMinutesInFuture = NOW + 3 * MINUTE;
    const fiveMinutesInFuture = NOW + 5 * MINUTE;
    const sevenMinutesInFuture = NOW + 7 * MINUTE;
    const nineMinutesInFuture = NOW + 9 * MINUTE;

    let snapshotId;

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const latestBlock = await utils.web3async(web3.eth, web3.eth.getBlock, 'latest');
        initTime(latestBlock.timestamp);
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    const createJoule = async() => {
        const vault = await Vault.new();
        const storage = await Storage.new();

        const joule = await Joule.new(vault.address, 0, 0, storage.address);
        await vault.setJoule(joule.address);
        await storage.giveAccess(joule.address);

        const proxy = await Proxy.new();
        await proxy.setJoule(joule.address);
        await joule.setProxy(proxy.address);

        return proxy;
    };

    commonTest.init(accounts, createJoule);
    commonTest.forEachTest(function (test) {
        it(test.name, test.test);
    });
});