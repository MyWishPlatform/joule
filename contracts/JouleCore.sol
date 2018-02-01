pragma solidity ^0.4.19;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';
import './JouleVault.sol';

contract JouleCore is JouleContractHolder {
    JouleVault public vault;
    using KeysUtils for bytes32;

    function JouleCore(JouleVault _vault, bytes32 _head, uint _length, JouleStorage _storage) public
        JouleContractHolder(_head, _length, _storage) {
        vault = _vault;
    }

    function innerRegister(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal returns (uint) {
        uint price = getPriceInner(_gasLimit, _gasPrice);
        require(msg.value >= price);
        vault.transfer(price);

        // this restriction to avoid attack to brake index tree (crossing key)
        require(_address != 0);
        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit <= MAX_GAS);
        // from 1 gwei to 0x100000000 gwei
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        insert(_address, _timestamp, _gasLimit, _gasPrice / GWEI);
        saveRegistrant(_registrant, _address, _timestamp, _gasLimit, _gasPrice / GWEI);

        if (msg.value > price) {
            msg.sender.transfer(msg.value - price);
            return msg.value - price;
        }
        return 0;
    }

    function saveRegistrant(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal {
        uint gasWithFlag = OWNER_FLAG;
        assembly {
            gasWithFlag := or(_gasLimit, gasWithFlag)
        }
        bytes32 id = KeysUtils.toKey(_address, _timestamp, gasWithFlag, _gasPrice);
        state.set(id, bytes32(_registrant));
    }

    function getRegistrant(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal view returns (address) {
        uint gasWithFlag = OWNER_FLAG;
        assembly {
            gasWithFlag := or(_gasLimit, gasWithFlag)
        }
        bytes32 id = KeysUtils.toKey(_address, _timestamp, gasWithFlag, _gasPrice);
        return address(state.get(id));
    }

    function findKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public view returns (bytes32) {
        require(_address != 0);
        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit < MAX_GAS);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);
        return findPrevious(_address, _timestamp, _gasLimit, _gasPrice);
    }

    function innerUnregister(address _registrant, bytes32 _key, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal returns (uint) {
        // only future registrations might be updated, to avoid race condition in block (with invoke)
        require(_timestamp > now);
        // to avoid removing already removed keys
        require(_gasLimit != 0);
        uint innerGasPrice = _gasPrice / GWEI;
        // check registrant
        address registrant = getRegistrant(_address, _timestamp, _gasLimit, innerGasPrice);
        require(registrant == _registrant);

        updateGas(_key, _address, _timestamp, _gasLimit, innerGasPrice, 0);
        uint amount = _gasLimit * _gasPrice;
        if (amount != 0) {
            _registrant.transfer(amount);
        }
        return amount;
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        require(_gasLimit <= MAX_GAS);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        return getPriceInner(_gasLimit, _gasPrice);
    }

    function getPriceInner(uint _gasLimit, uint _gasPrice) internal pure returns (uint) {
        // if this logic will be changed, look also to the innerUnregister method
        return (_gasLimit + IDLE_GAS) * _gasPrice;
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

    function innerInvoke(address _invoker) internal returns (uint _amount) {
        KeysUtils.Object memory current = KeysUtils.toObject(head);

        uint amount;
        while (current.timestamp != 0 && current.timestamp < now && msg.gas > (current.gasLimit + REMAINING_GAS)) {
            if (current.gasLimit != 0) {
                invokeCallback(_invoker, current);
            }

            amount += getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);
            current = next();
        }
        if (amount > 0) {
            vault.withdraw(msg.sender, amount);
        }
        return amount;
    }

    function innerInvokeOnce(address _invoker) internal returns (uint _amount) {
        KeysUtils.Object memory current = KeysUtils.toObject(head);
        next();
        if (current.gasLimit != 0) {
            invokeCallback(_invoker, current);
        }

        uint amount = getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);

        if (amount > 0) {
            vault.withdraw(msg.sender, amount);
        }
        return amount;
    }


    function invokeCallback(address, KeysUtils.Object memory _record) internal returns (bool) {
        require(msg.gas >= _record.gasLimit);
        return _record.contractAddress.call.gas(_record.gasLimit)(0x919840ad);
    }

}
