// const chai = require("chai");
// chai.use(require("chai-as-promised"));
// chai.should();
function Test(name, test) {
    this.name = name;
    this.test = test;
}
let suit;
let tests = [];
module.exports = {
    init: function (accounts, create) {
        tests = [];
        suit(accounts, create);
    },
    forEachTest: function (callback) {
        tests.forEach(callback);
    }
};

const it = (name, test) => {
    tests.push(new Test(name, test))
};

const contract = function (_, _suit) {
    suit = _suit;
};

const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const utils = require('./web3Utils');
const BigNumber = require('bignumber.js');
// chai.use(require("chai-bignumber")(BigNumber));

const Contract0kGas = artifacts.require("./Contract0kGas.sol");
const Contract100kGas = artifacts.require("./Contract100kGas.sol");
const Contract200kGas = artifacts.require("./Contract200kGas.sol");
const Contract300kGas = artifacts.require("./Contract300kGas.sol");
const Contract400kGas = artifacts.require("./Contract400kGas.sol");

const SECOND = 1;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

const JOULE_GAS = 62000;

let NOW, TOMORROW, DAY_AFTER_TOMORROW;

const initTime = (now) => {
    NOW = now;
    TOMORROW = now + DAY;
    DAY_AFTER_TOMORROW = TOMORROW + DAY;
};

initTime(new Date("2017-10-10T15:00:00Z").getTime() / 1000);

contract('JouleCommon', (accounts, createJoule) => {
    const OWNER = accounts[0];
    const SENDER = accounts[1];
    const SECOND_OWNER = accounts[2];

    const addresses = accounts;

    const gasLimit1 = 99990;
    const gasLimit2 = 199965;
    const gasLimit3 = 299983;
    const gasLimit4 = 399958;

    const ETH = web3.toWei(BigNumber(1), 'ether');
    const GWEI = web3.toWei(BigNumber(1), 'gwei');
    const ZERO_BYTES32 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
    const gasPrice1 = web3.toWei(20, 'gwei');
    const gasPrice2 = web3.toWei(30, 'gwei');
    const gasPrice3 = web3.toWei(40, 'gwei');
    const gasPrice4 = web3.toWei(50, 'gwei');

    const nowPlus3minutes = NOW + 3 * MINUTE;
    const nowPlus5minutes = NOW + 5 * MINUTE;
    const nowPlus7minutes = NOW + 7 * MINUTE;
    const nowPlus9minutes = NOW + 9 * MINUTE;

    const toHexWithIntPadding = (value) => ("00000000" + BigNumber(value).toString(16)).substr(-8, 8);
    const toKey = (address, timestamp, gas, price) => address + toHexWithIntPadding(timestamp) + toHexWithIntPadding(gas) + toHexWithIntPadding(BigNumber(price).div(GWEI));

    it('#0 gas usage', async () => {
        const joule = await createJoule();
        const contract0k = await Contract0kGas.new();
        console.info('gas 0k:', await contract0k.check.estimateGas());
        const contract100k = await Contract100kGas.new();
        console.info('gas 100k:', await contract100k.check.estimateGas());

        const gasLimit = BigNumber(100000);
        const gasPrice = web3.toWei(BigNumber(40), 'gwei');
        const price = await joule.getPrice(gasLimit, gasPrice);
        const jouleGas = price.minus(BigNumber(gasLimit).times(gasPrice)).div(gasPrice);

        await joule.register(contract0k.address, nowPlus3minutes, gasLimit, gasPrice, {value: price});
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit, gasPrice, {value: price});
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit, gasPrice, {value: price});
        await joule.register(contract100k.address, nowPlus9minutes, gasLimit, gasPrice, {value: price});

        const gasIdle = await joule.invoke.estimateGas({gas: gasLimit.times(2)});

        await increaseTime(4 * MINUTE);

        const gas0kCheck = await joule.invoke.estimateGas({gas: gasLimit.times(2)});

        const tx = await joule.invoke({gas: gasLimit.times(2)});
        tx.logs[0].event.should.be.equals('Invoked', 'checked event expected.');
        tx.logs[0].args._status.should.be.true;
        const inner0kCheck = tx.logs[0].args._usedGas;
        const delta0kCheck = BigNumber(gas0kCheck).minus(inner0kCheck);
        jouleGas.should.be.bignumber.gte(delta0kCheck);

        await increaseTime(2 * MINUTE);

        const gas100kCheck = await joule.invoke.estimateGas({gas: gasLimit.times(2)});
        const tx100k = await joule.invoke({gas: gasLimit.times(2)});
        tx100k.logs[0].event.should.be.equals('Invoked', 'checked event expected.');
        tx100k.logs[0].args._status.should.be.true;
        const inner100kCheck = tx100k.logs[0].args._usedGas;
        const delta100kCheck = BigNumber(gas100kCheck).minus(inner100kCheck);
        jouleGas.should.be.bignumber.gte(delta100kCheck);

        await increaseTime(4 * MINUTE);

        const gas2x100kCheck = await joule.invoke.estimateGas({gas: gasLimit.times(3)});
        const tx2x100k = await joule.invoke({gas: gasLimit.times(3)});
        tx2x100k.logs.length.should.be.equals(2, 'must be 2 events');
        tx2x100k.logs[0].event.should.be.equals('Invoked', 'checked event expected.');
        tx2x100k.logs[0].args._status.should.be.true;
        tx2x100k.logs[1].event.should.be.equals('Invoked', 'checked event expected.');
        tx2x100k.logs[1].args._status.should.be.true;
        tx2x100k.logs[0].args._usedGas
            .plus(tx2x100k.logs[1].args._usedGas)
            .should.be.bignumber.equals(inner100kCheck.times(2));

        console.info('Gas usages:');
        console.info("\tidle:", gasIdle);
        console.info('\tinner 0k check: ', String(inner0kCheck));
        console.info("\tsingle 0k check:", gas0kCheck);
        console.info("\tdelta 0k check:", String(delta0kCheck));
        console.info('\tinner 100k check: ', String(inner100kCheck));
        console.info("\tsingle 100k check:", gas100kCheck);
        console.info("\tdelta 100k check:", String(delta100kCheck));
        console.info('\tinner 2x100k check: ', String(inner100kCheck));
        console.info("\tsingle 2x100k check:", gas2x100kCheck);
        console.info("\tdelta 2x100k check:", BigNumber(gas2x100kCheck).minus(inner100kCheck.times(2)).toString());
    });

    it('#1 registration restrictions', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        const gasLimit = 100000;
        const highGasLimit = 4500000;

        const gasPrice = web3.toWei(2, 'gwei');
        const lowGasPrice = web3.toWei(0.5, 'gwei');
        const highGasPrice = web3.toWei(0x100000001, 'gwei');

        const price = await joule.getPrice(gasLimit, gasPrice);
        const lowPrice = price - 1;

        const fiveMinutesInPast = NOW - 5 * MINUTE;

        // too low price
        await joule
            .register(address, nowPlus5minutes, gasLimit, gasPrice, {value: lowPrice})
            .should.eventually.be.rejected;

        // time in the past
        await joule
            .register(address, fiveMinutesInPast, gasLimit, gasPrice, {value: price})
            .should.eventually.be.rejected;

        // too high gas limit
        await joule
            .register(address, nowPlus5minutes, highGasLimit, gasPrice, {value: ETH})
            .should.eventually.be.rejected;

        // too low gas price
        await joule
            .register(address, nowPlus5minutes, gasLimit, lowGasPrice, {value: ETH})
            .should.eventually.be.rejected;

        // too high gas price
        await joule
            .register(address, nowPlus5minutes, gasLimit, highGasPrice, {value: ETH})
            .should.eventually.be.rejected;
    });

    it('#2 correct registration', async () => {
        const joule = await createJoule();

        const price = await joule.getPrice(gasLimit1, gasPrice1);

        for (const i in addresses) {
            const a = addresses[i];
            await joule.register(a, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        }
    });

    it('#3 register and get next', async () => {
        const joule = await createJoule();

        const price1 = await joule.getPrice(gasLimit1, gasPrice1);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price1});
            // console.info(address, nowPlus7minutes, String(tx.logs[0].args.timestamp));
        }));

        const price2 = await joule.getPrice(gasLimit2, gasPrice2);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, nowPlus5minutes, gasLimit2, gasPrice2, {value: price2});
            // console.info(address, nowPlus5minutes, String(tx.logs[0].args.timestamp));
        }));

        const price3 = await joule.getPrice(gasLimit3, gasPrice3);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, nowPlus9minutes, gasLimit3, gasPrice3, {value: price3});
            // console.info(address, nowPlus9minutes, String(tx.logs[0].args.timestamp));
        }));

        const price4 = await joule.getPrice(gasLimit4, gasPrice4);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, nowPlus3minutes, gasLimit4, gasPrice4, {value: price4});
            // console.info(address, nowPlus3minutes, String(tx.logs[0].args.timestamp));
        }));

        const length = Number(await joule.getCount());
        length.should.be.equals(addresses.length * 4);
        const result = await joule.getTop(length);

        for (let i = 0; i < addresses.length; i++) {
            result[0][i].should.be.equals(addresses[i]);
            Number(result[1][i]).should.be.equals(nowPlus3minutes);
            Number(result[2][i]).should.be.equals(gasLimit4);
            Number(result[3][i]).should.be.equals(Number(gasPrice4));
        }
        for (let i = addresses.length; i < addresses.length * 2; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length]);
            Number(result[1][i]).should.be.equals(nowPlus5minutes);
            Number(result[2][i]).should.be.equals(gasLimit2);
            Number(result[3][i]).should.be.equals(Number(gasPrice2));
        }
        for (let i = addresses.length * 2; i < addresses.length * 3; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 2]);
            Number(result[1][i]).should.be.equals(nowPlus7minutes);
            Number(result[2][i]).should.be.equals(gasLimit1);
            Number(result[3][i]).should.be.equals(Number(gasPrice1));
        }
        for (let i = addresses.length * 3; i < addresses.length * 4; i++) {
            result[0][i].should.be.equals(addresses[i - addresses.length * 3]);
            Number(result[1][i]).should.be.equals(nowPlus9minutes);
            Number(result[2][i]).should.be.equals(gasLimit3);
            Number(result[3][i]).should.be.equals(Number(gasPrice3));
        }
    });

    it('#4 simple check one contract', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        const price2 = await joule.getPrice(gasLimit2, gasPrice2);
        const price1 = await joule.getPrice(gasLimit1, gasPrice1);

        await joule.register(address2, nowPlus5minutes, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, nowPlus3minutes, gasLimit1, gasPrice1, {value: price1});
        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + JOULE_GAS)});

        Number(await joule.getCount()).should.be.equals(1);

        const result = await joule.getTop(1);
        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(nowPlus5minutes);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));
    });


    it('#5 check and return funds', async () => {
        const joule = await createJoule();
        const contract = await Contract100kGas.new();
        const gasLimit = await contract.check.estimateGas();

        const price = await joule.getPrice(gasLimit, gasPrice1);

        await joule.register(contract.address, nowPlus3minutes, gasLimit, gasPrice1, {value: price});

        await increaseTime(nowPlus3minutes);

        const balanceBefore = await utils.getBalance(SENDER);
        await joule.invoke({from: SENDER, gasPrice: gasPrice1, gas: gasLimit + JOULE_GAS});
        const balanceAfter = await utils.getBalance(SENDER);
        // console.info(String(balanceBefore), '<=', String(balanceAfter));
        BigNumber(balanceBefore).comparedTo(BigNumber(balanceAfter)).should.be.lte(0, 'balanceBefore <= balanceAfter');
    });


    it('#6 check multiple contracts', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        const price1 = await joule.getPrice(gasLimit1, gasPrice1);
        const price2 = await joule.getPrice(gasLimit2, gasPrice2);

        await joule.register(address2, nowPlus5minutes, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, nowPlus3minutes, gasLimit1, gasPrice1, {value: price1});

        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + gasLimit2 + JOULE_GAS * 2)});

        Number(await joule.getCount()).should.be.equals(0);
    });

    it('#7 insert before head', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        const price1 = await joule.getPrice(gasLimit1, gasPrice1);
        const price2 = await joule.getPrice(gasLimit2, gasPrice2);

        await joule.register(address2, nowPlus5minutes, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, nowPlus3minutes, gasLimit1, gasPrice1, {value: price1});

        Number(await joule.getCount()).should.be.equals(2);
        const result = await joule.getTop(2);

        result[0][0].should.be.equals(address1);
        Number(result[1][0]).should.be.equals(nowPlus3minutes);
        Number(result[2][0]).should.be.equals(gasLimit1);
        Number(result[3][0]).should.be.equals(Number(gasPrice1));

        result[0][1].should.be.equals(address2);
        Number(result[1][1]).should.be.equals(nowPlus5minutes);
        Number(result[2][1]).should.be.equals(gasLimit2);
        Number(result[3][1]).should.be.equals(Number(gasPrice2));
    });

    it('#8 insert-insert-check-insert', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address1, nowPlus7minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address2, nowPlus3minutes, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address3, nowPlus3minutes, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address2, nowPlus5minutes, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await increaseTime(4 * MINUTE);
        await joule.invoke({gas: Number(gasLimit2 + gasLimit2 + 200000)});
        await joule.register(address3, nowPlus9minutes, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});

        Number(await joule.getCount()).should.be.equals(3);
        const result = await joule.getTop(3);

        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(nowPlus5minutes);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));

        result[0][1].should.be.equals(address1);
        Number(result[1][1]).should.be.equals(nowPlus7minutes);
        Number(result[2][1]).should.be.equals(gasLimit1);
        Number(result[3][1]).should.be.equals(Number(gasPrice1));

        result[0][2].should.be.equals(address3);
        Number(result[1][2]).should.be.equals(nowPlus9minutes);
        Number(result[2][2]).should.be.equals(gasLimit3);
        Number(result[3][2]).should.be.equals(Number(gasPrice3));
    });

    it('#9 check chain of contracts same timestamps', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address2, nowPlus3minutes, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address3, nowPlus3minutes, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});
        await joule.register(address1, nowPlus3minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address3, nowPlus5minutes, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});

        await increaseTime(4 * MINUTE);
        await joule.invoke({gas: Number(gasLimit2 + gasLimit3 + JOULE_GAS)});
        await joule.register(address1, nowPlus5minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});

        Number(await joule.getCount()).should.be.equals(3);
        const result = await joule.getTop(3);

        result[0][0].should.be.equals(address1);
        Number(result[1][0]).should.be.equals(nowPlus3minutes);
        Number(result[2][0]).should.be.equals(gasLimit1);
        Number(result[3][0]).should.be.equals(Number(gasPrice1));

        result[0][1].should.be.equals(address3);
        Number(result[1][1]).should.be.equals(nowPlus5minutes);
        Number(result[2][1]).should.be.equals(gasLimit3);
        Number(result[3][1]).should.be.equals(Number(gasPrice3));

        result[0][2].should.be.equals(address1);
        Number(result[1][2]).should.be.equals(nowPlus5minutes);
        Number(result[2][2]).should.be.equals(gasLimit1);
        Number(result[3][2]).should.be.equals(Number(gasPrice1));
    });

    it('#10 check with low gas', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;
        await joule.register(address, nowPlus5minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});

        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 / 2)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#11 check with extra gas but not in time', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        await joule.register(address, nowPlus3minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address, nowPlus5minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await increaseTime(3 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 * 2 + 100000)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#12 check with extra time but with insufficient gas', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        await joule.register(address, nowPlus3minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address, nowPlus5minutes, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + 100000)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#13 check change on register', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        const balanceBefore = await utils.getBalance(OWNER);
        const price = await joule.getPrice(gasLimit1, gasPrice1);
        const tx = await joule.register(address, nowPlus5minutes, gasLimit1, gasPrice1, {
            value: price.add(price),
            gasPrice: gasPrice1
        });
        const weiUsed = BigNumber(tx.receipt.gasUsed).times(gasPrice1);

        Number(await joule.getCount()).should.be.equals(1);

        const balanceAfter = await utils.getBalance(OWNER);

        const deltaBalance = balanceBefore.sub(weiUsed).sub(balanceAfter);

        deltaBalance.should.be.bignumber.equals(price, 'delta balance should be equals with price');
    });

    it('#14 duplicate key register', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();
        const contract200k = await Contract200kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        const price12 = await joule.getPrice(gasLimit1, gasPrice2);
        const price21 = await joule.getPrice(gasLimit2, gasPrice1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        // duplicate in the head
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        // duplicate address and time, but other price
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice2, {value: price12})
            .should.be.eventually.rejected;
        // duplicate address and time, but other gas
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit2, gasPrice1, {value: price21})
            .should.be.eventually.rejected;

        await joule.register(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        // duplicate in the middle
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
        // duplicate at the end
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
    });

    it('#15 findKey', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();
        const contract200k = await Contract200kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        const firstSingleKey = await joule.findKey(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1);
        firstSingleKey.should.be.equals(ZERO_BYTES32, "first (single) key must be zero");

        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        const secondKey = await joule.findKey(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        String(secondKey).should.be.equals(
            toKey(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1),
            "key for second value must be previous key"
        );

        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        const fiveKey = await joule.findKey(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        String(fiveKey).should.be.equals(toKey(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1),
            "key should be previous added contract with the same time");
        await joule.register(contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        // check insert before
        await joule.register(contract200k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        const secondKeyAgain = await joule.findKey(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        String(secondKeyAgain).should.be.equals(
            toKey(contract200k.address, nowPlus3minutes, gasLimit1, gasPrice1),
            "key for second value must be just added contract with low time"
        );

        await joule.register(contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});

        const firstKey = await joule.findKey(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1);
        firstKey.should.be.equals(ZERO_BYTES32, "first key must be zero");

        const fiveKeyAgain = await joule.findKey(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        String(fiveKeyAgain).should.be.equals(toKey(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1),
            "key should be previous added contract with the same time, without changing after insert");

    });

    it('#16 unregister', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();
        const contract200k = await Contract200kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});

        // to remove
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});

        await joule.register(contract100k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});

        // te remove
        await joule.register(contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});

        await joule.register(contract200k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});

        // check fist
        const topBefore = await joule.getTopOnce();
        topBefore[2].should.be.bignumber.equals(BigNumber(gasLimit1), "first should be");
        topBefore[0].should.be.equals(contract100k.address, "first should be");
        topBefore[1].should.be.bignumber.equals(BigNumber(nowPlus3minutes), "first should be");

        const keyFirst = await joule.findKey(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1);
        await joule.unregister(keyFirst, contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {gasPrice: 0});
        const topAfter = await joule.getTopOnce();
        topAfter[2].should.be.bignumber.equals(BigNumber(0), "gas for removed contract should be 0");

        // check middle
        const key = await joule.findKey(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1);
        const balanceBefore = await utils.getBalance(OWNER);
        await joule.unregister(key, contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {gasPrice: 0});
        const balanceAfter = await utils.getBalance(OWNER);
        const deltaBalance = balanceAfter.minus(balanceBefore).abs();
        deltaBalance.should.be.bignumber.equals(BigNumber(gasLimit1).times(gasPrice1), "should be returned only gas * price, without extra");

        // check invoke
        await increaseTime(nowPlus9minutes + 1);
        const balanceBeforeInvoke = await utils.getBalance(OWNER);
        await joule.invokeOnce({gasPrice: 0});
        const balanceAfterInvoke = await utils.getBalance(OWNER);
        const deltaBalanceInvoke = balanceAfterInvoke.minus(balanceBeforeInvoke).abs();
        const expectedPrice = await joule.getPrice(gasLimit1, gasPrice1);
        const removedPrice = expectedPrice.minus(BigNumber(gasLimit1).times(gasPrice1));
        deltaBalanceInvoke.should.be.bignumber.equals(removedPrice, "should be returned ext price - gas * price");
    });

    it('#17 find next after head key with the same timestamp', async () => {
        const joule = await createJoule();
        const contract0k = await Contract0kGas.new();
        const contract100k = await Contract100kGas.new();

        const gasLimit = BigNumber(100000);
        const gasPrice = web3.toWei(BigNumber(40), 'gwei');
        const price = await joule.getPrice(gasLimit, gasPrice);

        await joule.register(contract0k.address, nowPlus3minutes, gasLimit, gasPrice, {value: price});
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit, gasPrice, {value: price});

        const key = await joule.findKey(contract100k.address, nowPlus3minutes, gasLimit, gasPrice);
        key.should.be.not.equals(ZERO_BYTES32, "must not be empty key");
    });

    it('#18 register for, then unregister', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        await joule.registerFor(SECOND_OWNER, contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});

        const key = await joule.findKey(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1);
        // unregister by owner should be rejected
        await joule.unregister(key, contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1)
            .should.be.eventually.rejected;
        await joule.unregister(key, contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {from: SECOND_OWNER});
    });

    it('#19 getNextOnce/getNext', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();
        const contract200k = await Contract200kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});

        const once = await joule.getNextOnce(0, 0, 0, 0);
        const top = await joule.getTopOnce();

        once.length.should.be.equals(top.length, "getNextOnce with zeroes should returns the same like getTopOnce");
        once[0].should.be.equals(top[0], "getNextOnce with zeroes should returns the same like getTopOnce");
        once[0].should.be.equals(contract100k.address, "getNextOnce should return first registered");
        String(once[1]).should.be.equals(String(nowPlus3minutes), "getNextOnce should return first registered");

        const second = await joule.getNextOnce(once[0], once[1], once[2], once[3]);
        second[0].should.be.equals(contract200k.address);
        String(second[1]).should.be.equals(String(nowPlus3minutes));

        const multi5first = await joule.getNext(5, 0, 0, 0, 0);
        multi5first[0].length.should.be.equals(5);
        multi5first[0][0].should.be.equals(contract100k.address);
        multi5first[0][1].should.be.equals(contract200k.address);

        String(multi5first[1][0]).should.be.equals(String(nowPlus3minutes));
        String(multi5first[1][2]).should.be.equals(String(nowPlus5minutes));

        const multi5next = await joule.getNext(5, multi5first[0][4], multi5first[1][4], multi5first[2][4], multi5first[3][4]);
        multi5next[0].length.should.be.equals(5);

        // 6th registration
        multi5next[0][0].should.be.equals(contract200k.address);
        String(multi5next[1][0]).should.be.equals(String(nowPlus7minutes));

        multi5next[0][4].should.be.equals(ZERO_ADDRESS);
        String(multi5next[1][4]).should.be.equals(String(0));
    });

    it('#20 getMinGasPrice/gas price limit', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();

        const minGasPrice = await joule.getMinGasPrice();
        String(minGasPrice).should.be.equals(String(gasPrice1));

        const lessGasPrice = BigNumber(gasPrice1).minus(1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, lessGasPrice, {value: ETH})
            .should.be.eventually.rejected;
    });

    it('#21 untegister last then add to the end', async () => {
        const joule = await createJoule();
        const contract100k = await Contract100kGas.new();
        const contract200k = await Contract200kGas.new();

        const price = await joule.getPrice(gasLimit1, gasPrice1);
        await joule.register(contract100k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, nowPlus3minutes, gasLimit1, gasPrice1, {value: price});
        // 1: get key, remove
        await joule.register(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        // 2: get key (2,3,4,5), remove
        await joule.register(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1, {value: price});
        // 5: failed, because key is obsolete
        await joule.register(contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        // 4
        await joule.register(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});
        // 3
        await joule.register(contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1, {value: price});

        const key1 = await joule.findKey(contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        await joule.unregister(key1, contract100k.address, nowPlus5minutes, gasLimit1, gasPrice1);

        const key2 = await joule.findKey(contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        const key3 = await joule.findKey(contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1);
        const key4 = await joule.findKey(contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1);
        const key5 = await joule.findKey(contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1);

        await joule.unregister(key2, contract200k.address, nowPlus5minutes, gasLimit1, gasPrice1);
        await joule.unregister(key3, contract200k.address, nowPlus9minutes, gasLimit1, gasPrice1);
        await joule.unregister(key4, contract100k.address, nowPlus7minutes, gasLimit1, gasPrice1);
        await joule.unregister(key5, contract200k.address, nowPlus7minutes, gasLimit1, gasPrice1)
            .should.eventually.be.rejected;

        const top = await joule.getTop(50);
        String(top[2][2]).should.be.equals("0");
        String(top[2][3]).should.be.equals("0");
        String(top[2][4]).should.be.not.equals("0");
        String(top[2][5]).should.be.equals("0");
    });

});