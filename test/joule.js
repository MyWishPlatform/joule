const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const {web3async} = require('./web3Utils');

const Joule = artifacts.require("./Joule.sol");
const CheckableContract = artifacts.require("./CheckableContractImpl.sol");

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
    const OWNER = accounts[0];

    const addresses = accounts;

    const gasLimit1 = 1000000;
    const gasLimit2 = 2000000;
    const gasLimit3 = 3000000;
    const gasLimit4 = 4000000;

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
        const latestBlock = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        initTime(latestBlock.timestamp);
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#1 insertion restrictions', async () => {
        const joule = await Joule.new();
        const address = (await CheckableContract.new()).address;

        const gasLimit = 1000000;
        const highGasLimit = 4500000;

        const gasPrice = web3.toWei(2, 'gwei');
        const lowGasPrice = web3.toWei(0.5, 'gwei');
        const highGasPrice = web3.toWei(0x100000001, 'gwei');

        const fiveMinutesInPast = NOW - 5 * MINUTE;

        await joule.insert(address, fiveMinutesInPast, gasLimit, gasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, highGasLimit, gasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, gasLimit, lowGasPrice).should.eventually.be.rejected;
        await joule.insert(address, fiveMinutesInFuture, gasLimit, highGasPrice).should.eventually.be.rejected;
    });

    it('#2 correct insertion', async () => {
        const joule = await Joule.new();

        addresses.forEach(async (a) => {
            await joule.insert(a, fiveMinutesInFuture, gasLimit1, gasPrice1);
        });
    });

    it('#3 insert and get next', async () => {
        const joule = await Joule.new();

        addresses.forEach(async (address) => {
            await joule.insert(address, sevenMinutesInFuture, gasLimit1, gasPrice1);
        });

        addresses.forEach(async (address) => {
            await joule.insert(address, fiveMinutesInFuture, gasLimit2, gasPrice2);
        });

        addresses.forEach(async (address) => {
            await joule.insert(address, nineMinutesInFuture, gasLimit3, gasPrice3);
        });

        addresses.forEach(async (address) => {
            await joule.insert(address, threeMinutesInFuture, gasLimit4, gasPrice4);
        });

        const length = Number(await joule.length());
        length.should.be.greaterThan(0);
        const result = await joule.getNext(length);

        for (let i = 0; i < addresses.length; i++) {
            result[0][i].should.be.equals(addresses[i]);
            Number(result[1][i]).should.be.equals(threeMinutesInFuture);
            Number(result[2][i]).should.be.equals(gasLimit4);
            Number(result[3][i]).should.be.equals(Number(gasPrice4));
        }
        for (let i = addresses.length; i < addresses.length * 2; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length]);
            Number(result[1][i]).should.be.equals(fiveMinutesInFuture);
            Number(result[2][i]).should.be.equals(gasLimit2);
            Number(result[3][i]).should.be.equals(Number(gasPrice2));
        }
        for (let i = addresses.length * 2; i < addresses.length * 3; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 2]);
            Number(result[1][i]).should.be.equals(sevenMinutesInFuture);
            Number(result[2][i]).should.be.equals(gasLimit1);
            Number(result[3][i]).should.be.equals(Number(gasPrice1));
        }
        for (let i = addresses.length * 3; i < addresses.length * 4; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 3]);
            Number(result[1][i]).should.be.equals(nineMinutesInFuture);
            Number(result[2][i]).should.be.equals(gasLimit3);
            Number(result[3][i]).should.be.equals(Number(gasPrice3));
        }
    });

    it('#4 simple check one contract', async () => {
        const joule = await Joule.new();

        const address1 = (await CheckableContract.new()).address;
        const address2 = (await CheckableContract.new()).address;

        await joule.insert(address2, fiveMinutesInFuture, gasLimit2, gasPrice2);
        await joule.insert(address1, threeMinutesInFuture, gasLimit1, gasPrice1);

        await joule.check(Number(gasLimit1 * gasPrice1));

        Number(await joule.length()).should.be.equals(1);

        const result = await joule.getNext(1);
        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));
    });

    it('#5 check multiple contracts', async () => {
        const joule = await Joule.new();

        const address1 = (await CheckableContract.new()).address;
        const address2 = (await CheckableContract.new()).address;

        await joule.insert(address2, fiveMinutesInFuture, gasLimit2, gasPrice2);
        await joule.insert(address1, threeMinutesInFuture, gasLimit1, gasPrice1);

        await joule.check(Number(gasLimit1 * gasPrice1 + gasLimit2 * gasPrice2));

        Number(await joule.length()).should.be.equals(0);
    });
});