const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
const {web3async} = require('./web3Utils');

const JouleIndex = artifacts.require("./JouleIndex.sol");
const Storage = artifacts.require("./JouleStorage.sol");

const BYTES32_ZERO = "0x0000000000000000000000000000000000000000000000000000000000000000";
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

const createIndex = async () => {
    const storage = await Storage.new();
    const index = await JouleIndex.new(storage.address);
    await storage.giveAccess(index.address);
    return index;
};

contract('JouleIndex', accounts => {
    const OWNER = accounts[0];

    let snapshotId;

    function toKey(timestamp) {
        return OWNER + ("00000000" + Number(timestamp).toString(16)).substr(-8, 8) + "0000ac00" + "00000020";
    }

    function toKey2(timestamp) {
        return OWNER + ("00000000" + Number(timestamp).toString(16)).substr(-8, 8) + "0000ac00" + "00f00020";
    }

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const latestBlock = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        initTime(latestBlock.timestamp);
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#1 insert and find', async () => {
        const index = await createIndex();

        const dates = [
            new Date("2017-10-20T15:00:00Z").getTime() / 1000,
            new Date("2017-10-30T15:00:00Z").getTime() / 1000,
            new Date("2017-10-31T15:00:00Z").getTime() / 1000,
            new Date("2017-10-31T16:00:00Z").getTime() / 1000,
            new Date("2017-10-31T17:00:00Z").getTime() / 1000,
            new Date("2017-11-10T15:00:00Z").getTime() / 1000,
            new Date("2017-11-13T15:00:00Z").getTime() / 1000,
        ];
        const randomOrder = [3, 5, 1, 0, 2, 6, 4];

        for (const i in randomOrder) {
            const dateIndex = randomOrder[i];
            const ts = dates[dateIndex];
            await index.insert(toKey(ts));
        }

        for (const i in dates) {
            const ts = dates[i] - 1;
            const key = await index.findFloorKey(ts);
            if (Number(i) === 0) {
                String(key).should.be.equals(BYTES32_ZERO);
            }
            else {
                String(key).should.be.equals(toKey(dates[i - 1]));
            }
        }
    });

    it('#2 find single', async () => {
        const index = await createIndex();

        const ts = new Date("2017-10-20T15:00:00Z").getTime() / 1000;

        await index.insert(toKey(ts));

        const zeroKey = await index.findFloorKey(ts - 1);
        String(zeroKey).should.be.equals(BYTES32_ZERO, "before ts must be empty");

        const exactKey = await index.findFloorKey(ts);
        String(exactKey).should.be.equals(toKey(ts), "exact ts must be the same");

        const nextKey = await index.findFloorKey(ts + 1);
        String(nextKey).should.be.equals(toKey(ts), "next ts must be the same");
    });

    it('#3 gas calculation, worst case', async () => {
        // the worst case when we on week level has two values: the first week and the last in the year
        // and try to find pre last week ts, where week is 604800 seconds
        // year is 31449600
        const index = await createIndex();

        const first = new Date("2016-12-20T03:00:00").getTime() / 1000;
        const next = new Date("2016-12-27T03:00:01").getTime() / 1000;
        // const second = new Date("2017-06-20T03:00:00").getTime() / 1000;
        // const prelast = new Date("2017-10-26T02:00:00").getTime() / 1000;
        const prelast = new Date("2017-11-02T02:59:58").getTime() / 1000;
        const last = new Date("2017-11-02T02:59:59").getTime() / 1000;
        const nextYear = new Date("2017-11-02T03:00:00").getTime() / 1000;

        const firstInsertGas = await index.insert.estimateGas(toKey(first));
        console.info("first insert: ", firstInsertGas, "gas");
        await index.insert(toKey(first));
        const sameYearGas = await index.insert.estimateGas(toKey(last));
        console.info("next insert: ", sameYearGas, "gas");
        await index.insert(toKey(last));
        const nextYearGas = await index.insert.estimateGas(toKey(nextYear));
        console.info("new year insert: ", nextYearGas, "gas");

        const firstKey = await index.findFloorKey(next);
        String(firstKey).should.be.equals(toKey(first));

        const normalCaseGas = await index.findFloorKey.estimateGas(next);
        console.info("normal search: ", normalCaseGas, "gas");

        const worstCaseGas = await index.findFloorKey.estimateGas(prelast);
        console.info("worst search: ", worstCaseGas, "gas");

        const firstKeyAgain = await index.findFloorKey(prelast);
        String(firstKeyAgain).should.be.equals(toKey(first));
    });

    it('#4 update', async () => {
        const index = await createIndex();

        const dates = [
            new Date("2017-10-20T15:00:00Z").getTime() / 1000,
            new Date("2017-10-30T15:00:00Z").getTime() / 1000,
            new Date("2017-10-31T15:00:00Z").getTime() / 1000,
            new Date("2017-10-31T16:00:00Z").getTime() / 1000,
            new Date("2017-10-31T17:00:00Z").getTime() / 1000,
            new Date("2017-11-10T15:00:00Z").getTime() / 1000,
            new Date("2017-11-13T15:00:00Z").getTime() / 1000,
        ];
        const randomOrder = [3, 5, 1, 0, 2, 6, 4];

        for (const i in randomOrder) {
            const dateIndex = randomOrder[i];
            const ts = dates[dateIndex];
            await index.insert(toKey(ts));
        }

        for (const i in randomOrder) {
            const dateIndex = randomOrder[i];
            const ts = dates[dateIndex];
            await index.update(toKey(ts), toKey2(ts));
        }

        for (const i in dates) {
            const ts = dates[i] - 1;
            const key = await index.findFloorKey(ts);
            if (Number(i) === 0) {
                String(key).should.be.equals(BYTES32_ZERO);
            }
            else {
                String(key).should.be.equals(toKey2(dates[i - 1]));
            }
        }
    });
});