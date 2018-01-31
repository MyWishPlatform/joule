const JouleNative = artifacts.require("./Joule.sol");
const Joule = artifacts.require("./JouleBehindProxy.sol");
const Proxy = artifacts.require("./JouleProxy.sol");
const Storage = artifacts.require("./JouleStorage.sol");
const Vault = artifacts.require("./JouleVault.sol");

module.exports = function(deployer, network, accounts) {
    return deployer.deploy(Storage)
        .then(function () {
            return deployer.deploy(Vault);
        })
        .then(function () {
            return deployer.deploy(Joule, Vault.address, 0, 0, Storage.address);
        })
        .then(function () {
            return Joule.deployed();
        })
        .then(function (jouleInstance) {
            return deployer.deploy(Proxy)
                .then (function () {
                    return Proxy.deployed();
                })
                .then (function (proxyInstance) {
                    console.info("setJoule to proxy");
                    return proxyInstance.setJoule(jouleInstance.address)
                        .then (function () {
                            console.info("setProxy to joule");
                            return jouleInstance.setProxy(proxyInstance.address)
                                .then (function () {
                                    return jouleInstance;
                                });
                        });
                });
        })
        .then(function (jouleInstance) {
            console.info("get Storage instance");
            return Storage.deployed()
                .then (function (storageInstance) {
                    console.info("Storage give access to joule");
                    return storageInstance.giveAccess(jouleInstance.address)
                        .then (function () {
                            console.info("get Index address");
                            return jouleInstance.index()
                                .then (function (indexAddress) {
                                    console.info("Storage give access to index");
                                    return storageInstance.giveAccess(indexAddress);
                                });
                        });
                })
                .then(function () {
                    console.info("get Vault address");
                    return Vault.deployed()
                        .then(function (vaultInstance) {
                            console.info("set Joule to Vault");
                            return vaultInstance.setJoule(jouleInstance.address);
                        });
                });
        });
};