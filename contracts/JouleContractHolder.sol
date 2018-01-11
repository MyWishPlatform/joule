pragma solidity ^0.4.0;

import './JouleConsts.sol';
import './JouleIndex.sol';

contract JouleContractHolder is usingConsts, JouleIndex {

    uint public length;
    bytes32 head;
    mapping (bytes32 => KeysUtils.Object) objects;

    function insert(address _address, uint32 _timestamp, uint32 _gasLimit, uint32 _gasPrice) internal {
        bytes32 id = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        bytes32 current = findFloorKey(_timestamp);
        objects[id] = objects[current];
        objects[current] = KeysUtils.Object(_gasPrice, _gasLimit, _timestamp, _address);
        super.insert(id);
        length++;
    }

    function removeNext() internal {
        KeysUtils.Object memory obj = getNext();
        delete objects[head];
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
        uint i = 0;
        while (i < amount) {
            addresses[i] = objects[current].contractAddress;
            timestamps[i] = objects[current].timestamp;
            gasLimits[i] = objects[current].gasLimit;
            gasPrices[i] = objects[current].gasPrice * GWEI;

            current = KeysUtils.toKey(objects[current]);
            i++;
        }
    }
}
