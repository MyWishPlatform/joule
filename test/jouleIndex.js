const chai = require("chai");
chai.use(require("chai-as-promised"));
chai.should();
const {increaseTime, revert, snapshot, mine} = require('./evmMethods');
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

    function toKey(timestamp) {
        return OWNER + ("00000000" + Number(timestamp).toString(16)).substr(-4, 8) + "0000ac00" + "00000020";
    }

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
            const ts = dates[i];
            const key = await index.findFloorKey(ts);
            if (i === 0) {
                Number(key).should.be.equals(0);
            }
            else {
                String(key).should.be.equals(toKey(dates[i - 1]));
            }
        }
    });

});