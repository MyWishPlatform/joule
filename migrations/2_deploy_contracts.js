const Joule = artifacts.require("./Joule.sol");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(Joule);
};