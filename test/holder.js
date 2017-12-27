const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {web3async} = require('./web3Utils');

const JouleContractHolder = artifacts.require("./JouleContractHolder.sol");

const SECONDS = 1;
const MINUTES = 60 * SECONDS;
const HOURS = 60 * MINUTES;
const DAYS = 24 * HOURS;

let NOW, TOMORROW, DAY_AFTER_TOMORROW;

const initTime = (now) => {
    NOW = now;
    TOMORROW = now + DAYS;
    DAY_AFTER_TOMORROW = TOMORROW + DAYS;
};

initTime(new Date("2017-10-10T15:00:00Z").getTime() / 1000);

contract('Holder', accounts => {
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

    it('#1 check decompose timestamp', async () => {
        const holder = await JouleContractHolder.deployed();
        const date = new Date(NOW * 1000);

        const dates = await holder.decomposeTimestamp(NOW);
        Number(dates[0]).should.be.equals(date.getUTCFullYear(), 'years should be equals');
        Number(dates[1]).should.be.equals(date.getUTCMonth() + 1, 'months should be equals');
        Number(dates[2]).should.be.equals(date.getUTCDate(), 'days should be equals');
        Number(dates[3]).should.be.equals(date.getUTCHours(), 'hours should be equals');
        Number(dates[4]).should.be.equals(date.getUTCMinutes(), 'minutes should be equals');
    });

    it('#2 check insert before now', async () => {
        const holder = await JouleContractHolder.deployed();
        const addresses = accounts;

        const before5minutes = NOW - 5 * MINUTES;

        addresses.forEach(async (a) => {
            await holder.insert(a, before5minutes).should.eventually.be.rejected;
        });
    });

    it('#3 check insert after now', async () => {
        const holder = await JouleContractHolder.deployed();
        const addresses = accounts;

        const after5minutes = NOW + 5 * MINUTES;

        addresses.forEach(async (a) => {
            await holder.insert(a, after5minutes);
        });
    });

    it('#4 check insert and get next', async () => {
        const holder = await JouleContractHolder.deployed();
        const addresses = accounts;

        const after5minutes = NOW + 5 * MINUTES;
        const after7minutes = NOW + 7 * MINUTES;
        const after9minutes = NOW + 9 * MINUTES;

        addresses.forEach(async (a) => {
            await holder.insert(a, after7minutes);
            await holder.insert(a, after5minutes);
            await holder.insert(a, after9minutes);
        });

        const getNextResult = await holder.getNext();
        const resultAddresses = getNextResult[0];
        const resultTimestamp = getNextResult[1];

        for (let i = 0; i < addresses.length; i++) {
            resultAddresses[i].should.be.equals(addresses[i]);
        }
        Math.trunc(Number(resultTimestamp) / 60).should.be.equals(Math.trunc(after5minutes / 60));
    });
});