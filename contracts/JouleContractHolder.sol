pragma solidity ^0.4.0;

import './JouleConsts.sol';
import './JouleIndex.sol';

contract JouleContractHolder is usingConsts, JouleIndex {

    uint public length;
    bytes32 head;
    mapping (bytes32 => KeysUtils.Object) objects;

    function insert(address _address, uint32 _timestamp, uint32 _gasLimit, uint32 _gasPrice) internal {
        bytes32 id = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        bytes32 previous = findFloorKey(_timestamp);
        uint prevTimestamp = KeysUtils.getTimestamp(previous);
        uint headTimestamp = KeysUtils.getTimestamp(head);
        if (prevTimestamp < headTimestamp) {
            previous = head;
        }
        objects[id] = objects[previous];
        objects[previous] = KeysUtils.Object(_gasPrice, _gasLimit, _timestamp, _address);
        super.insert(id);
        length++;
    }

    function removeNext() internal {
        KeysUtils.Object memory obj = getNext();
//        delete objects[head];
        head = KeysUtils.toKey(obj);
        length--;
    }

    function getNext() internal view returns (KeysUtils.Object) {
        return objects[head];
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
            addresses[i] = objects[current].contractAddress;
            timestamps[i] = objects[current].timestamp;
            gasLimits[i] = objects[current].gasLimit;
            gasPrices[i] = objects[current].gasPrice * GWEI;

            current = KeysUtils.toKey(objects[current]);
        }
    }
}
