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

    function () public payable onlyJoule {
    }

    function getCount() public view returns (uint) {
        return joule.getCount();
    }

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint) {
        uint change = joule.register.value(msg.value)(_address, _timestamp, _gasLimit, _gasPrice);
        if (change > 0) {
            msg.sender.transfer(change);
        }
        return change;
    }

    function invoke() public returns (uint) {
        uint amount = joule.invoke();
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
        return amount;
    }

    function invokeTop() public returns (uint) {
        uint amount = joule.invokeTop();
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
        return amount;
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

    function getNext(address _contractAddress,
                     uint _timestamp,
                     uint _gasLimit,
                     uint _gasPrice) public view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice
    ) {
        (contractAddress, timestamp, gasLimit, gasPrice) = joule.getNext(_contractAddress, _timestamp, _gasLimit, _gasPrice);
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

        address contractAddress;
        uint timestamp;
        uint gasLimit;
        uint gasPrice;

        (contractAddress, timestamp, gasLimit, gasPrice) = joule.getTop();
        _addresses[0] = contractAddress;
        _timestamps[0] = timestamp;
        _gasLimits[0] = gasLimit;
        _gasPrices[0] = gasPrice;

        for (uint i = 1; i < amount; i ++) {
            (contractAddress, timestamp, gasLimit, gasPrice) = joule.getNext(contractAddress, timestamp, gasLimit, gasPrice);
            _addresses[i] = contractAddress;
            _timestamps[i] = timestamp;
            _gasLimits[i] = gasLimit;
            _gasPrices[i] = gasPrice;
        }
    }

    function getVersion() external view returns (bytes8) {
        return joule.getVersion();
    }

    function callback(address _contract) public onlyJoule {
        CheckableContract(_contract).check();
    }
}
