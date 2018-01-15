pragma solidity ^0.4.19;

import './JouleConsts.sol';
import './JouleIndex.sol';

contract JouleContractHolder is usingConsts {

    uint public length;
    bytes32 head;
    mapping (bytes32 => KeysUtils.Object) objects;
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
            return;
        }
        bytes32 previous = index.findFloorKey(_timestamp);
        uint prevTimestamp = KeysUtils.getTimestamp(previous);
        uint headTimestamp = KeysUtils.getTimestamp(head);
        if (prevTimestamp < headTimestamp) {
            previous = head;
        }
        objects[id] = objects[previous];
        objects[previous] = KeysUtils.Object(uint32(_gasPrice), uint32(_gasLimit), uint32(_timestamp), _address);
        index.insert(id);
    }

    function next() internal returns (KeysUtils.Object storage _next) {
        _next = objects[head];
        head = KeysUtils.toKeyFromStorage(_next);
        length--;
    }

    function getNext(uint _count) external view returns (
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
            KeysUtils.Object memory obj = KeysUtils.toObject(current);
            addresses[i] = obj.contractAddress;
            timestamps[i] = obj.timestamp;
            gasLimits[i] = obj.gasLimit;
            gasPrices[i] = obj.gasPrice;
            current = KeysUtils.toKey(objects[current]);
        }
    }
}
