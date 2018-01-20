pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './JouleAPI.sol';
import './JouleBehindProxy.sol';
import './TransferToken.sol';
import './JouleProxyAPI.sol';
import './CheckableContract.sol';

contract JouleProxy is JouleProxyAPI, JouleAPI, Ownable, TransferToken {
    JouleBehindProxy public joule;

    function setJoule(JouleBehindProxy _joule) public onlyOwner {
        joule = _joule;
    }

    modifier onlyJoule() {
        require(msg.sender == address(joule));
        _;
    }

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable {
        joule.register.value(msg.value)(_address, _timestamp, _gasLimit, _gasPrice);
    }

    function invoke() external {
        uint amount = joule.invokeFromProxy();
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
    }

    function getCount() public view returns (uint) {
        return joule.getCount();
    }

    function invokeTop() external {
        uint amount = joule.invokeTopFromProxy();
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        return joule.getPrice(_gasLimit, _gasPrice);
    }

    function getTop() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice
    ) {
        (contractAddress, timestamp, gasLimit, gasPrice) = joule.getTop();
    }

    function getTop(uint _count) external view returns (
        address[] _addresses,
        uint[] _timestamps,
        uint[] _gasLimits,
        uint[] _gasPrices
    ) {
        uint length = joule.getCount();
        uint amount = _count <= length ? _count : length;

        _addresses = new address[](amount);
        _timestamps = new uint[](amount);
        _gasLimits = new uint[](amount);
        _gasPrices = new uint[](amount);

        joule.getTopInParams(_addresses, _timestamps, _gasLimits, _gasPrices);
    }

    function getTopInParams(address[] memory _addresses, uint[] memory _timestamps, uint[] memory _gasLimits, uint[] memory _gasPrices) public view {
        joule.getTopInParams(_addresses, _timestamps, _gasLimits, _gasPrices);
    }


    function getVersion() external view returns (uint) {
        return joule.getVersion();
    }

    function callback(address _contract) external onlyJoule {
        CheckableContract(_contract).check();
    }
}
