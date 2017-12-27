const JouleContractHolder = artifacts.require("./JouleContractHolder.sol");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(JouleContractHolder);
};