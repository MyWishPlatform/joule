const ether = '0000000000000000000';
const ganache = require("ganache-cli");
require('./utils/revertTime.js');

const ganacheConfig = () => {
    return {
        network_id: "5777",
        provider: ganache.provider({
            accounts: [10, 100, 10000, 1000000, 1].map(function (v) {
                return {balance: "" + v + ether};
            }),
            mnemonic: "mywish",
            time: new Date("2017-10-10T15:00:00Z"),
            debug: false
            // ,logger: console
        })
    };
};
module.exports = {
    networks: {
        ganache: ganacheConfig(),
        localhost: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        develop: ganacheConfig(),
        debug: {
            host: "localhost",
            port: 9545,
            network_id: "*" // Match any network id
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    network: 'ganache',
    mocha: {
        bail: true,
        fullTrace: true,
    }
};