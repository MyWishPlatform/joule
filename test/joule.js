const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {web3async} = require('./web3Utils');

const Joule = artifacts.require("./Joule.sol");

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

contract('Joule', accounts => {
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

    it('#1 insertion restrictions', async () => {
        const joule = await Joule.deployed();
        const address = accounts[0];

        const gasLimit = 1000000;
        const highGasLimit = 4500000;

        const gasPrice = web3.toWei(2, 'gwei');
        const lowGasPrice = web3.toWei(0.5, 'gwei');
        const highGasPrice = web3.toWei(0x100000001, 'gwei');

        const fiveMinutesInPast = NOW - 5 * MINUTES;
        const fiveMinutesInFuture = NOW + 5 * MINUTES;

        await joule.insert(address, fiveMinutesInPast, gasLimit, gasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, highGasLimit, gasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, gasLimit, lowGasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, gasLimit, highGasPrice).should.eventually.be.rejected;
    });

    it('#2 correct insertion', async () => {
        const joule = await Joule.deployed();

        const addresses = accounts;
        const gasLimit = 1000000;
        const gasPrice = web3.toWei(2, 'gwei');
        const fiveMinutesInFuture = NOW + 5 * MINUTES;

        addresses.forEach(async (a) => {
            await joule.insert(a, fiveMinutesInFuture, gasLimit, gasPrice);
        });
    });

    it('#3 insert and get next', async () => {
        const joule = await Joule.deployed();

        const addresses = accounts;
        const timestamps = [7, 5, 9, 3].map(ts => NOW + ts * MINUTES);
        const gasLimits = [1, 2, 3, 4].map(limit => limit * 1000000);
        const gasPrices = [2, 3, 4, 5].map(price => web3.toWei(price, 'gwei'));

        for (let i = 0; i < addresses.length; i++) {
            for (let j = 0; j < timestamps.length; j++) {
                await joule.insert(addresses[i], timestamps[j], gasLimits[j], gasPrices[j])
            }
        }

        const length = Number(await joule.length());
        length.should.be.greaterThan(0);
        const result = await joule.getNext(length);

        for (let i = 0; i < timestamps.length; i++) {
            for (let j = 0; j < result[0].length; j++) {
                result[0][j].should.be.equals(addresses[j - addresses.length * i]);
                Number(result[1][i]).should.be.equals(timestamps[i]);
                Number(result[2][i]).should.be.equals(gasLimits[i]);
                Number(result[3][i]).should.be.equals(gasPrices[i]);
            }
        }
    });

    it('#4 check', async () => {
        const joule = await Joule.deployed();


    })
});