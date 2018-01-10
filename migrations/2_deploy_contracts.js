const Joule = artifacts.require("./Joule.sol");
const CheckableContract = artifacts.require("./CheckableContractImpl.sol");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(Joule);
    deployer.deploy(CheckableContract);
};