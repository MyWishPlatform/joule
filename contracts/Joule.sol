pragma solidity ^0.4.19;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';
import './JouleVault.sol';

contract Joule is JouleAPI, JouleContractHolder {
    JouleVault public vault;
    using KeysUtils for bytes32;

    function Joule(JouleVault _vault, bytes32 _head, uint _length, JouleStorage _storage) public
        JouleContractHolder(_head, _length, _storage) {
        vault = _vault;
    }

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint) {
        uint price = this.getPrice(_gasLimit, _gasPrice);
        require(msg.value >= price);
        vault.transfer(price);

        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit < MAX_GAS);
        // from 1 gwei to 0x100000000 gwei
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        insert(_address, _timestamp, _gasLimit, _gasPrice / GWEI);

        Registered(_address, _timestamp, _gasLimit, _gasPrice);

        if (msg.value > price) {
            msg.sender.transfer(msg.value - price);
            return msg.value - price;
        }
        return 0;
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        require(_gasLimit < 4300000);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        return getPriceInner(_gasLimit, _gasPrice);
    }

    function getPriceInner(uint _gasLimit, uint _gasPrice) internal pure returns (uint) {
        return (_gasLimit + IDLE_GAS) * _gasPrice;
    }

    function invoke() public returns (uint) {
        return innerInvoke(invokeCallback);
    }

    function invokeOnce() public returns (uint) {
        return innerInvokeTop(invokeCallback);
    }

    function getVersion() external view returns (bytes8) {
        return VERSION;
    }


    function getTop(uint _count) external view returns (
        address[] _addresses,
        uint[] _timestamps,
        uint[] _gasLimits,
        uint[] _gasPrices,
        uint[] _invokeGases,
        uint[] _rewardAmounts
    ) {
        uint amount = _count <= length ? _count : length;

        _addresses = new address[](amount);
        _timestamps = new uint[](amount);
        _gasLimits = new uint[](amount);
        _gasPrices = new uint[](amount);
        _invokeGases = new uint[](amount);
        _rewardAmounts = new uint[](amount);

        bytes32 current = getRecord(0);
        for (uint i = 0; i < amount; i ++) {
            KeysUtils.Object memory obj = current.toObject();
            _addresses[i] = obj.contractAddress;
            _timestamps[i] = obj.timestamp;
            uint gasLimit = obj.gasLimit;
            _gasLimits[i] = gasLimit;
            uint gasPrice = obj.gasPriceGwei * GWEI;
            _gasPrices[i] = gasPrice;
            uint invokeGas = gasLimit + IDLE_GAS;
            _invokeGases[i] = invokeGas;
            _rewardAmounts[i] = invokeGas * gasPrice;
            current = getRecord(current);
        }
    }

    function getTopOnce() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice,
        uint invokeGas,
        uint rewardAmount
    ) {
        KeysUtils.Object memory obj = getRecord(0).toObject();

        contractAddress = obj.contractAddress;
        timestamp = obj.timestamp;
        gasLimit = obj.gasLimit;
        gasPrice = obj.gasPriceGwei * GWEI;
        invokeGas = gasLimit + IDLE_GAS;
        rewardAmount = invokeGas * gasPrice;
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
        if (_timestamp == 0) {
            return this.getTopOnce();
        }

        bytes32 prev = KeysUtils.toKey(_contractAddress, _timestamp, _gasLimit, _gasPrice / GWEI);
        bytes32 current = getRecord(prev);
        KeysUtils.Object memory obj = current.toObject();

        contractAddress = obj.contractAddress;
        timestamp = obj.timestamp;
        gasLimit = obj.gasLimit;
        gasPrice = obj.gasPriceGwei * GWEI;
        invokeGas = gasLimit + IDLE_GAS;
        rewardAmount = invokeGas * gasPrice;
    }

    function innerInvoke(function (address, uint) internal returns (bool) _callback) internal returns (uint _amount) {
        KeysUtils.Object memory current = KeysUtils.toObject(head);

        uint amount;
        while (current.timestamp != 0 && current.timestamp < now && msg.gas > (current.gasLimit + IDLE_GAS_PRE)) {
            uint gas = msg.gas;
            bool status = _callback(current.contractAddress, current.gasLimit);
//            current.contractAddress.call.gas(current.gasLimit)(0x919840ad);
            gas -= msg.gas;
            Invoked(current.contractAddress, status, gas);

            amount += getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);
            current = next();
        }
        if (amount > 0) {
            vault.withdraw(msg.sender, amount);
        }
        return amount;
    }

    function innerInvokeTop(function (address, uint) internal returns (bool) _callback) internal returns (uint _amount) {
        KeysUtils.Object memory current = KeysUtils.toObject(head);
        next();
        uint gas = msg.gas;
        bool status = _callback(current.contractAddress, current.gasLimit);
        gas -= msg.gas;

        Invoked(current.contractAddress, status, gas);

        uint amount = getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);

        if (amount > 0) {
            vault.withdraw(msg.sender, amount);
        }
        return amount;
    }


    function invokeCallback(address _contract, uint _gas) internal returns (bool) {
        return _contract.call.gas(_gas)(0x919840ad);
    }

}
