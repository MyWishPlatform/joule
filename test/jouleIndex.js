const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const {web3async} = require('./web3Utils');

const JouleIndex = artifacts.require("./JouleIndex.sol");

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

contract('JouleIndex', accounts => {
    const OWNER = accounts[0];

    let snapshotId;

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const latestBlock = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        initTime(latestBlock.timestamp);
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#1 smoke test', async () => {
        const index = await JouleIndex.new();
    });

});