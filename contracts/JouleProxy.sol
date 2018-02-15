pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './JouleAPI.sol';
import './JouleBehindProxy.sol';
import './utils/TransferToken.sol';
import './JouleProxyAPI.sol';
import './CheckableContract.sol';

contract JouleProxy is JouleProxyAPI, JouleAPI, Ownable, TransferToken, usingConsts {
    JouleBehindProxy public joule;

    function setJoule(JouleBehindProxy _joule) public onlyOwner {
        joule = _joule;
    }

    modifier onlyJoule() {
        require(msg.sender == address(joule));
        _;
    }

    function () public payable {
    }

    function getCount() public view returns (uint) {
        return joule.getCount();
    }

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint) {
        return registerFor(msg.sender, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function registerFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public payable returns (uint) {
        Registered(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
        uint change = joule.registerFor.value(msg.value)(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
        if (change > 0) {
            msg.sender.transfer(change);
        }
        return change;
    }

    function unregister(bytes32 _key, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external returns (uint) {
        // unregister will return funds to registrant, not to msg.sender (unlike register)
        uint amount = joule.unregisterFor(msg.sender, _key, _address, _timestamp, _gasLimit, _gasPrice);
        Unregistered(msg.sender, _address, _timestamp, _gasLimit, _gasPrice, amount);
        return amount;
    }

    function findKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public view returns (bytes32) {
        return joule.findKey(_address, _timestamp, _gasLimit, _gasPrice);
    }

    function invoke() public returns (uint) {
        return invokeFor(msg.sender);
    }

    function invokeFor(address _invoker) public returns (uint) {
        uint amount = joule.invokeFor(_invoker);
        if (amount != 0) {
            msg.sender.transfer(amount);
        }
        return amount;
    }

    function invokeOnce() public returns (uint) {
        return invokeOnceFor(msg.sender);
    }

    function invokeOnceFor(address _invoker) public returns (uint) {
        uint amount = joule.invokeOnceFor(_invoker);
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

    function getNextOnce(address _contractAddress,
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
        (contractAddress, timestamp, gasLimit, gasPrice, invokeGas, rewardAmount) = joule.getNextOnce(_contractAddress, _timestamp, _gasLimit, _gasPrice);
    }


    function getNext(uint _count,
                    address _contractAddress,
                    uint _timestamp,
                    uint _gasLimit,
                    uint _gasPrice) external view returns (
        address[] _addresses,
        uint[] _timestamps,
        uint[] _gasLimits,
        uint[] _gasPrices,
        uint[] _invokeGases,
        uint[] _rewardAmounts
    ) {
        _addresses = new address[](_count);
        _timestamps = new uint[](_count);
        _gasLimits = new uint[](_count);
        _gasPrices = new uint[](_count);
        _invokeGases = new uint[](_count);
        _rewardAmounts = new uint[](_count);

        uint i = 0;

        (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getNextOnce(_contractAddress, _timestamp, _gasLimit, _gasPrice);

        for (i += 1; i < _count; i ++) {
            if (_timestamps[i - 1] == 0) {
                break;
            }
            (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getNextOnce(_addresses[i - 1], _timestamps[i - 1], _gasLimits[i - 1], _gasPrices[i - 1]);
        }
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

        uint i = 0;

        (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getTopOnce();

        for (i += 1; i < amount; i ++) {
            (_addresses[i], _timestamps[i], _gasLimits[i], _gasPrices[i], _invokeGases[i], _rewardAmounts[i]) = joule.getNextOnce(_addresses[i - 1], _timestamps[i - 1], _gasLimits[i - 1], _gasPrices[i - 1]);
        }
    }

    function getVersion() external view returns (bytes8) {
        return joule.getVersion();
    }

    function getMinGasPrice() public view returns (uint) {
        return joule.minGasPriceGwei() * GWEI;
    }

    function callback(address _invoker, address _address, uint, uint _gasLimit, uint) public onlyJoule returns (bool) {
        require(msg.gas >= _gasLimit);
        uint gas = msg.gas;
        bool status = _address.call.gas(_gasLimit)(0x919840ad);
        Invoked(_invoker, _address, status, gas - msg.gas);
        return status;
    }
}
