pragma solidity ^0.4.19;

import './JouleConsts.sol';
import './JouleIndex.sol';

contract JouleContractHolder is usingConsts {
    using KeysUtils for bytes32;
//    event Found(uint timestamp);
    uint public length;
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

    function getTop(uint _count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices
    ) {
        uint amount = _count <= length ? _count : length;

        addresses = new address[](amount);
        timestamps = new uint[](amount);
        gasLimits = new uint[](amount);
        gasPrices = new uint[](amount);

        bytes32 current = head;
        for (uint i = 0; i < amount; i ++) {
            KeysUtils.Object memory obj = current.toObject();
            addresses[i] = obj.contractAddress;
            timestamps[i] = obj.timestamp;
            gasLimits[i] = obj.gasLimit;
            gasPrices[i] = obj.gasPriceGwei * GWEI;
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
}
