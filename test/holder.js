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
        const gasLimit = 1000000;
        const before5minutes = NOW - 5 * MINUTES;

        addresses.forEach(async (a) => {
            await holder.insert(a, gasLimit, before5minutes).should.eventually.be.rejected;
        });
    });

    it('#3 check insert after now', async () => {
        const holder = await JouleContractHolder.deployed();

        const addresses = accounts;
        const gasLimit = 1000000;
        const after5minutes = NOW + 5 * MINUTES;

        addresses.forEach(async (a) => {
            await holder.insert(a, gasLimit, after5minutes);
        });
    });

    it('#4 check insert and get next', async () => {
        const holder = await JouleContractHolder.deployed();

        const addresses = accounts;

        const gasLimit1 = 1000000;
        const gasLimit2 = 2000000;
        const gasLimit3 = 3000000;
        const gasLimit4 = 4000000;

        const after3minutes = NOW + 3 * MINUTES;
        const after5minutes = NOW + 5 * MINUTES;
        const after7minutes = NOW + 7 * MINUTES;
        const after9minutes = NOW + 9 * MINUTES;

        addresses.forEach(async (address) => {
            await holder.insert(address, gasLimit1, after7minutes);
        });

        addresses.forEach(async (address) => {
            await holder.insert(address, gasLimit2, after5minutes);
        });

        addresses.forEach(async (address) => {
            await holder.insert(address, gasLimit3, after9minutes);
        });

        addresses.forEach(async (address) => {
            await holder.insert(address, gasLimit4, after3minutes);
        });


        const result = await holder.total();

        for (let i = 0; i < result[0].length; i++) {
            console.info(result[0][i], Number(result[1][i]), Number(result[2][i]));
        }

        for (let i = 0; i < addresses.length; i++) {
            result[0][i].should.be.equals(addresses[i]);
            Number(result[1][i]).should.be.equals(gasLimit4);
            Number(result[2][i]).should.be.equals(after3minutes);
        }
        for (let i = addresses.length; i < addresses.length * 2; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length]);
            Number(result[1][i]).should.be.equals(gasLimit2);
            Number(result[2][i]).should.be.equals(after5minutes);
        }
        for (let i = addresses.length * 2; i < addresses.length * 3; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 2]);
            Number(result[1][i]).should.be.equals(gasLimit1);
            Number(result[2][i]).should.be.equals(after7minutes);
        }
        for (let i = addresses.length * 3; i < addresses.length * 4; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 3]);
            Number(result[1][i]).should.be.equals(gasLimit3);
            Number(result[2][i]).should.be.equals(after9minutes);
        }
    });

    it('test getNext', async () => {
        const holder = await JouleContractHolder.deployed();

        await holder.insert(accounts[2], 2000000, NOW + MINUTES);
        await holder.insert(accounts[0], 1000000, NOW);
        await holder.insert(accounts[1], 2000000, NOW + 3 * MINUTES);

        const result = await holder.getNext();
        result[0].should.be.equals(accounts[0]);
        result[1].should.be.equals(100000);
        result[2].should.be.equals(NOW);
    });
});