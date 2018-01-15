const Joule = artifacts.require("./Joule.sol");

module.exports = function(deployer, network, accounts) {
    return deployer.deploy(Joule);
};