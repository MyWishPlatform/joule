const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {printNextContracts, printTxLogs} = require('./jouleUtils');
const utils = require('./web3Utils');
const BigNumber = require('bignumber.js');
chai.use(require("chai-bignumber")(BigNumber));

const Joule = artifacts.require("./Joule.sol");
const Storage = artifacts.require("./JouleStorage.sol");
const Vault = artifacts.require("./JouleVault.sol");
const Contract0kGas = artifacts.require("./Contract0kGas.sol");
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

    const createJoule = async () => {
        const vault = await Vault.new();
        const storage = await Storage.new();
        const joule = await Joule.new(vault.address, 0, 0, storage.address);
        await vault.setJoule(joule.address);
        await storage.giveAccess(joule.address);
        await storage.giveAccess(await joule.index());
        return joule;
    };

    it('#0 gas usage', async () => {
        const joule = await createJoule();
        const contract0k = await Contract0kGas.new();
        console.info('gas 0k:', await contract0k.check.estimateGas());
        const contract100k = await Contract100kGas.new();
        console.info('gas 100k:', await contract100k.check.estimateGas());

        const gasLimit = BigNumber(100000);
        const gasPrice = web3.toWei(BigNumber(40), 'gwei');
        const price = await joule.getPrice(gasLimit, gasPrice);

        await joule.register(contract0k.address, fiveMinutesInFuture, gasLimit, gasPrice, {value: price});
        await joule.register(contract100k.address, sevenMinutesInFuture, gasLimit, gasPrice, {value: price});

        const gasIdle = await joule.invoke.estimateGas({gas: gasLimit.times(2)});

        await increaseTime(6 * MINUTE);

        const gas0kCheck = await joule.invoke.estimateGas({gas: gasLimit.times(4)});

        const tx = await joule.invoke({gas: gasLimit.times(2)});
        tx.logs[0].event.should.be.equals('Invoked', 'checked event expected.');
        tx.logs[0].args._status.should.be.true;

        await increaseTime(2 * MINUTE);

        const gas100kCheck = await joule.invoke.estimateGas({gas: gasLimit.times(2)});
        const tx100k = await joule.invoke({gas: gasLimit.times(4)});
        tx100k.logs[0].event.should.be.equals('Invoked', 'checked event expected.');
        tx100k.logs[0].args._status.should.be.true;

        console.info('Gas usages:');
        console.info("\tidle:", gasIdle);
        console.info('\tinner 0k check: ', String(tx.logs[0].args._usedGas));
        console.info("\tsingle 0k check:", gas0kCheck);
        console.info('\tinner 100k check: ', String(tx100k.logs[0].args._usedGas));
        console.info("\tsingle 100k check:", gas100kCheck);
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
            .register(address, fiveMinutesInFuture, gasLimit, gasPrice, {value: lowPrice})
            .should.eventually.be.rejected;

        // time in the past
        await joule
            .register(address, fiveMinutesInPast, gasLimit, gasPrice, {value: price})
            .should.eventually.be.rejected;

        // too high gas limit
        await joule
            .register(address, fiveMinutesInFuture, highGasLimit, gasPrice, {value: ETH})
            .should.eventually.be.rejected;

        // too low gas price
        await joule
            .register(address, fiveMinutesInFuture, gasLimit, lowGasPrice, {value: ETH})
            .should.eventually.be.rejected;

        // too high gas price
        await joule
            .register(address, fiveMinutesInFuture, gasLimit, highGasPrice, {value: ETH})
            .should.eventually.be.rejected;
    });

    it('#2 correct registration', async () => {
        const joule = await createJoule();

        const price = await joule.getPrice(gasLimit1, gasPrice1);

        for (const i in addresses) {
            const a = addresses[i];
            await joule.register(a, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: price});
        }
    });

    it('#3 register and get next', async () => {
        const joule = await createJoule();

        const price1 = await joule.getPrice(gasLimit1, gasPrice1);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: price1});
            // console.info(address, sevenMinutesInFuture, String(tx.logs[0].args.timestamp));
        }));

        const price2 = await joule.getPrice(gasLimit2, gasPrice2);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: price2});
            // console.info(address, fiveMinutesInFuture, String(tx.logs[0].args.timestamp));
        }));

        const price3 = await joule.getPrice(gasLimit3, gasPrice3);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, nineMinutesInFuture, gasLimit3, gasPrice3, {value: price3});
            // console.info(address, nineMinutesInFuture, String(tx.logs[0].args.timestamp));
        }));

        const price4 = await joule.getPrice(gasLimit4, gasPrice4);

        await Promise.all(addresses.map(async (address) => {
            const tx = await joule.register(address, threeMinutesInFuture, gasLimit4, gasPrice4, {value: price4});
            // console.info(address, threeMinutesInFuture, String(tx.logs[0].args.timestamp));
        }));

        const length = Number(await joule.getCount());
        length.should.be.equals(addresses.length * 4);
        const result = await joule.getTop(length);

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
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        const price2 = await joule.getPrice(gasLimit2, gasPrice2);
        const price1 = await joule.getPrice(gasLimit1, gasPrice1);

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: price1});
        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + 50000)});

        Number(await joule.getCount()).should.be.equals(1);

        const result = await joule.getTop(1);
        result[0][0].should.be.equals(address2);
        Number(result[1][0]).should.be.equals(fiveMinutesInFuture);
        Number(result[2][0]).should.be.equals(gasLimit2);
        Number(result[3][0]).should.be.equals(Number(gasPrice2));
    });


    it('#5 check and return funds', async () => {
        const joule = await createJoule();
        const contract = await Contract100kGas.new();
        const gasLimit = await contract.check.estimateGas();

        const price = await joule.getPrice(gasLimit, gasPrice1);

        await joule.register(contract.address, threeMinutesInFuture, gasLimit, gasPrice1, {value: price});

        await increaseTime(threeMinutesInFuture);

        const balanceBefore = await utils.getBalance(SENDER);
        await joule.invoke({from: SENDER, gasPrice: gasPrice1, gas: gasLimit + 50000});
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

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: price1});

        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + gasLimit2 + 50000)});

        Number(await joule.getCount()).should.be.equals(0);
    });

    it('#7 insert before head', async () => {
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;

        const price1 = await joule.getPrice(gasLimit1, gasPrice1);
        const price2 = await joule.getPrice(gasLimit2, gasPrice2);

        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: price2});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: price1});

        Number(await joule.getCount()).should.be.equals(2);
        const result = await joule.getTop(2);

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
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address1, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address2, threeMinutesInFuture, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address3, threeMinutesInFuture, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address2, fiveMinutesInFuture, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await increaseTime(4 * MINUTE);
        await joule.invoke({gas: Number(gasLimit2 + gasLimit2 + 200000)});
        await joule.register(address3, nineMinutesInFuture, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});

        Number(await joule.getCount()).should.be.equals(3);
        const result = await joule.getTop(3);

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
        const joule = await createJoule();

        const address1 = (await Contract100kGas.new()).address;
        const address2 = (await Contract200kGas.new()).address;
        const address3 = (await Contract300kGas.new()).address;

        await joule.register(address2, threeMinutesInFuture, gasLimit2, gasPrice2, {value: await joule.getPrice(gasLimit2, gasPrice2)});
        await joule.register(address3, threeMinutesInFuture, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});
        await joule.register(address1, threeMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address3, fiveMinutesInFuture, gasLimit3, gasPrice3, {value: await joule.getPrice(gasLimit3, gasPrice3)});

        await increaseTime(4 * MINUTE);
        await joule.invoke({gas: Number(gasLimit2 + gasLimit3 + 50000)});
        await joule.register(address1, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});

        Number(await joule.getCount()).should.be.equals(3);
        const result = await joule.getTop(3);

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
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;
        await joule.register(address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});

        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 / 2)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#11 check with extra gas but not in time', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        await joule.register(address, threeMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await increaseTime(4 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 * 2 + 100000)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#12 check with extra time but with insufficient gas', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        await joule.register(address, threeMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await joule.register(address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: await joule.getPrice(gasLimit1, gasPrice1)});
        await increaseTime(6 * MINUTE);
        await joule.invoke({gas: Number(gasLimit1 + 100000)});

        Number(await joule.getCount()).should.be.equals(1);
    });

    it('#13 check change on register', async () => {
        const joule = await createJoule();
        const address = (await Contract100kGas.new()).address;

        const balanceBefore = await utils.getBalance(OWNER);
        const price = await joule.getPrice(gasLimit1, gasPrice1);
        const tx = await joule.register(address, fiveMinutesInFuture, gasLimit1, gasPrice1, {
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
        await joule.register(contract100k.address, threeMinutesInFuture, gasLimit1, gasPrice1, {value: price});
        // duplicate in the head
        await joule.register(contract100k.address, threeMinutesInFuture, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
        await joule.register(contract100k.address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract200k.address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: price});
        await joule.register(contract100k.address, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: price});
        // duplicate in the middle
        await joule.register(contract100k.address, fiveMinutesInFuture, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
        // duplicate at the end
        await joule.register(contract100k.address, sevenMinutesInFuture, gasLimit1, gasPrice1, {value: price})
            .should.be.eventually.rejected;
    });
});