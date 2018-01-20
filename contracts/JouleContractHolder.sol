pragma solidity ^0.4.19;

import './JouleConsts.sol';
import './JouleIndex.sol';

contract JouleContractHolder is usingConsts {
    using KeysUtils for bytes32;
//    event Found(uint timestamp);
    uint internal length;
    bytes32 head;
    mapping (bytes32 => bytes32) objects;
    JouleIndex index;

    function JouleContractHolder() public {
        index = new JouleIndex();
    }

    function insert(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal {
        length ++;
        bytes32 id = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        if (head == 0) {
            head = id;
            index.insert(id);
//            Found(0xffffffff);
            return;
        }
        bytes32 previous = index.findFloorKey(_timestamp);

        // reject duplicate key on the end
        require(previous != id);
        // reject duplicate in the middle
        require(objects[id] == 0);

        uint prevTimestamp = previous.getTimestamp();
//        Found(prevTimestamp);
        uint headTimestamp = head.getTimestamp();
        // add as head, prevTimestamp == 0 or in the past
        if (prevTimestamp < headTimestamp) {
            objects[id] = head;
            head = id;
        }
        // add after the previous
        else {
            objects[id] = objects[previous];
            objects[previous] = id;
        }
        index.insert(id);
    }

    function next() internal returns (KeysUtils.Object memory _next) {
        head = objects[head];
        length--;
        _next = head.toObject();
    }

    function getCount() public view returns (uint) {
        return length;
    }

    function getTop(uint _count) external view returns (
        address[] _addresses,
        uint[] _timestamps,
        uint[] _gasLimits,
        uint[] _gasPrices
    ) {
        uint amount = _count <= length ? _count : length;

        _addresses = new address[](amount);
        _timestamps = new uint[](amount);
        _gasLimits = new uint[](amount);
        _gasPrices = new uint[](amount);

        bytes32 current = head;
        for (uint i = 0; i < amount; i ++) {
            KeysUtils.Object memory obj = current.toObject();
            _addresses[i] = obj.contractAddress;
            _timestamps[i] = obj.timestamp;
            _gasLimits[i] = obj.gasLimit;
            _gasPrices[i] = obj.gasPriceGwei * GWEI;
            current = objects[current];
        }
    }

    function getTop() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice
    ) {
        KeysUtils.Object memory obj = head.toObject();

        contractAddress = obj.contractAddress;
        timestamp = obj.timestamp;
        gasLimit = obj.gasLimit;
        gasPrice = obj.gasPriceGwei * GWEI;
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
        if (_timestamp == 0) {
            return this.getTop();
        }

        bytes32 prev = KeysUtils.toKey(_contractAddress, _timestamp, _gasLimit, _gasPrice / GWEI);
        bytes32 current = objects[prev];
        KeysUtils.Object memory obj = current.toObject();

        contractAddress = obj.contractAddress;
        timestamp = obj.timestamp;
        gasLimit = obj.gasLimit;
        gasPrice = obj.gasPriceGwei * GWEI;
    }
}
