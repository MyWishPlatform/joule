const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const {web3async} = require('./web3Utils');

const Joule = artifacts.require("./Joule.sol");
const Contract100kGas = artifacts.require("./Contract100kGas.sol");
const Contract200kGas = artifacts.require("./Contract200kGas.sol");
const Contract300kGas = artifacts.require("./Contract300kGas.sol");
const Contract400kGas = artifacts.require("./Contract400kGas.sol");

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

    const gasLimit1 = 99990;
    const gasLimit2 = 199965;
    const gasLimit3 = 299983;
    const gasLimit4 = 399958;

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

    it('#1 registration restrictions', async () => {
        const joule = await Joule.new();
        const address = (await Contract100kGas.new()).address;

        const gasLimit = 100000;
        const highGasLimit = 4500000;

        const gasPrice = web3.toWei(2, 'gwei');
        const lowGasPrice = web3.toWei(0.5, 'gwei');
        const highGasPrice = web3.toWei(0x100000001, 'gwei');

        const fiveMinutesInPast = NOW - 5 * MINUTE;

        await joule
            .register(address, fiveMinutesInPast, gasLimit, gasPrice, {value: gasLimit * gasPrice})
            .should.eventually.be.rejected;

        await joule
            .register(address, fiveMinutesInFuture, highGasLimit, gasPrice, {value: highGasLimit * gasPrice})
            .should.eventually.be.rejected;

        await joule
            .register(address, fiveMinutesInFuture, gasLimit, lowGasPrice, {value: gasLimit * lowGasPrice})
            .should.eventually.be.rejected;

        await joule
            .register(address, fiveMinutesInFuture, gasLimit, highGasPrice, {value: gasLimit * highGasPrice})
            .should.eventually.be.rejected;
    });

    it('#2 correct registration', async () => {
        const joule = await Joule.new();

        addresses.forEach(async (a) => {
            await joule.register(a, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});
        });
    });

    it('#3 register and get next', async () => {
        const joule = await Joule.new();

        addresses.forEach(async (address) => {
            await joule.register(address, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});
        });

        addresses.forEach(async (address) => {
            await joule.register(address, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        });

        addresses.forEach(async (address) => {
            await joule.register(address, nineMinutesInFuture, gasLimit3, gasPrice3, {value: gasLimit3 * gasPrice3});
        });

        addresses.forEach(async (address) => {
            await joule.register(address, threeMinutesInFuture, gasLimit4, gasPrice4, {value: gasLimit4 * gasPrice4});
        });

        const length = Number(await joule.length());
        length.should.be.equals(addresses.length * 4);
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

    it('#4 register with lack of funds', async () => {
        const joule = await Joule.new();
        const contract = await Contract100kGas.new();
        const gasLimit = await contract.check.estimateGas();
        await joule
            .register(contract.address, fiveMinutesInFuture, gasLimit, gasPrice1, {value: gasLimit * gasPrice1 / 2})
            .should.eventually.be.rejected;
    });

    it('#5 simple check one contract', async () => {
        const joule = await Joule.new();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});
        await increaseTime(6 * MINUTE);
        await joule.check({gas: Number(gasLimit1 + 50000)});

        Number(await joule.length()).should.be.equals(1);

        const result = await joule.getNext(1);
        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));
    });

    it('#6 check multiple contracts', async () => {
        const joule = await Joule.new();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});

        await increaseTime(6 * MINUTE);
        await joule.check({gas: Number(gasLimit1 + gasLimit2 + 50000)});

        Number(await joule.length()).should.be.equals(0);
    });

    it('#7 insert before head', async () => {
        const joule = await Joule.new();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});

        Number(await joule.length()).should.be.equals(2);
        const result = await joule.getNext(2);

        result[0][0].should.be.equals(address1);
        Number(result[1][0]).should.be.equals(threeMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit1);
        Number(result[3][0]).should.be.equals(Number(gasPrice1));

        result[0][1].should.be.equals(address2);
        Number(result[1][1]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][1]).should.be.equals(gasLimit2);
        Number(result[3][1]).should.be.equals(Number(gasPrice2));
    });

    it('#8 insert-insert-check-insert', async () => {
        const joule = await Joule.new();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address1, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});
        await joule.register(address2, threeMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address3, threeMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await increaseTime(4 * MINUTE);
        await joule.check({gas: Number(gasLimit2 + gasLimit2 + 200000)});
        await joule.register(address3, nineMinutesInFuture, gasLimit3, gasPrice3, {value: gasLimit3 * gasPrice3 * 2});

        Number(await joule.length()).should.be.equals(3);
        const result = await joule.getNext(3);

        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));

        result[0][1].should.be.equals(address1);
        Number(result[1][1]).should.be.equals(sevenMinutesInFuture);
        Number(result[2][1]).should.be.equals(gasLimit1);
        Number(result[3][1]).should.be.equals(Number(gasPrice1));

        result[0][2].should.be.equals(address3);
        Number(result[1][2]).should.be.equals(nineMinutesInFuture);
        Number(result[2][2]).should.be.equals(gasLimit3);
        Number(result[3][2]).should.be.equals(Number(gasPrice3));
    });

    it('#9 check chain of contracts same timestamps', async () => {
        const joule = await Joule.new();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address2, threeMinutesInFuture, gasLimit2, gasPrice2, {value: gasLimit2 * gasPrice2});
        await joule.register(address3, threeMinutesInFuture, gasLimit3, gasPrice3, {value: gasLimit3 * gasPrice3});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});
        await joule.register(address3, fiveMinutesInFuture, gasLimit3, gasPrice3, {value: gasLimit3 * gasPrice3});

        await increaseTime(4 * MINUTE);
        await joule.check({gas: Number(gasLimit2 + gasLimit3 + 50000)});
        await joule.register(address1, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});

        Number(await joule.length()).should.be.equals(3);
        const result = await joule.getNext(3);

        result[0][0].should.be.equals(address1);
        Number(result[1][0]).should.be.equals(threeMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit1);
        Number(result[3][0]).should.be.equals(Number(gasPrice1));

        result[0][1].should.be.equals(address3);
        Number(result[1][1]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][1]).should.be.equals(gasLimit3);
        Number(result[3][1]).should.be.equals(Number(gasPrice3));

        result[0][2].should.be.equals(address1);
        Number(result[1][2]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][2]).should.be.equals(gasLimit1);
        Number(result[3][2]).should.be.equals(Number(gasPrice1));
    });

    it('#10 check with low gas', async () => {
        const joule = await Joule.new();
        const address = (await Contract100kGas.new()).address;
        await joule.register(address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: gasLimit1 * gasPrice1});

        await increaseTime(6 * MINUTE);
        await joule.check({gas: Number(gasLimit1 / 2)});

        Number(await joule.length()).should.be.equals(1);
    });
});