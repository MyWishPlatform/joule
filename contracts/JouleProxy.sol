pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './JouleAPI.sol';
import './JouleBehindProxy.sol';
import './utils/TransferToken.sol';
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

    function () public payable {
//        require(msg.sender == address(joule) || msg.sender == address(joule.vault()));
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

    function invokeOnce() public returns (uint) {
        uint amount = joule.invokeOnce();
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
        return amount;
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        return joule.getPrice(_gasLimit, _gasPrice);
    }

    function getTopOnce() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice,
        uint invokeGas,
        uint rewardAmount
    ) {
        (contractAddress, timestamp, gasLimit, gasPrice, invokeGas, rewardAmount) = joule.getTopOnce();
    }

    function getNext(address _contractAddress,
                     uint _timestamp,
                     uint _gasLimit,
                     uint _gasPrice) public view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice,
        uint invokeGas,
        uint rewardAmount
    ) {
        (contractAddress, timestamp, gasLimit, gasPrice, invokeGas, rewardAmount) = joule.getNext(_contractAddress, _timestamp, _gasLimit, _gasPrice);
    }

    function getTop(uint _count) external view returns (
        address[] _addresses,
        uint[] _timestamps,
        uint[] _gasLimits,
        uint[] _gasPrices,
        uint[] _invokeGases,
        uint[] _rewardAmounts
    ) {
        uint length = joule.getCount();
        uint amount = _count <= length ? _count : length;

        _addresses = new address[](amount);
        _timestamps = new uint[](amount);
        _gasLimits = new uint[](amount);
        _gasPrices = new uint[](amount);
        _invokeGases = new uint[](amount);
        _rewardAmounts = new uint[](amount);

//        address contractAddress;
//        uint timestamp;
//        uint gasLimit;
//        uint gasPrice;
//        uint invokeGas;
//        uint rewardAmount;

        uint i = 0;

//        (contractAddress, timestamp, gasLimit, gasPrice, invokeGas, rewardAmount) = joule.getTopOnce();
        (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getTopOnce();
//        _addresses[0] = contractAddress;
//        _timestamps[0] = timestamp;
//        _gasLimits[0] = gasLimit;
//        _gasPrices[0] = gasPrice;
//        _invokeGases[0] = invokeGas;
//        _rewardAmounts[0] = rewardAmount;

        for (i += 1; i < amount; i ++) {
            (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getNext(_addresses[i - 1], _timestamps[i - 1], _gasLimits[i - 1], _gasPrices[i - 1]);
//            (contractAddress, timestamp, gasLimit, gasPrice, invokeGas, rewardAmount) = joule.getNext(contractAddress, timestamp, gasLimit, gasPrice);
//            _addresses[i] = contractAddress;
//            _timestamps[i] = timestamp;
//            _gasLimits[i] = gasLimit;
//            _gasPrices[i] = gasPrice;
//            _invokeGases[i] = invokeGas;
//            _rewardAmounts[i] = rewardAmount;
        }
    }

    function getVersion() external view returns (bytes8) {
        return joule.getVersion();
    }

    function callback(address _contract) public onlyJoule {
        CheckableContract(_contract).check();
    }
}
