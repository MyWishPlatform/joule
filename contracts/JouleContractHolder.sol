pragma solidity ^0.4.0;

import './JouleConsts.sol';

contract JouleContractHolder is usingConsts {

    struct Object {
        address contractAddress;
        uint32 timestamp;
        uint32 gasLimit;
        uint32 gasPrice;
    }

    uint public length;
    bytes32 head;
    mapping (bytes32 => Object) objects;

    function toKey(Object _obj) internal pure returns (bytes32) {
        return toKey(_obj.contractAddress, _obj.timestamp, _obj.gasLimit, _obj.gasPrice);
    }

    function toKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal pure returns (bytes32 result) {
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ - address
        //                                                 ^^^^^^^^ - timestamp
        //                                                         ^^^^^^^^ - gas limit
        //                                                                 ^^^^^^^^ - gas price
        assembly {
            result := or(result, mul(_address, 0x1000000000000000000000000))
            result := or(result, mul(and(_timestamp, 0xffffffff), 0x10000000000000000))
            result := or(result, mul(and(_gasLimit, 0xffffffff), 0x100000000))
            result := or(result, and(_gasPrice, 0xffffffff))
        }
    }

    function insert(address _address, uint32 _timestamp, uint32 _gasLimit, uint32 _gasPrice) internal {
        bytes32 id = toKey(_address, _timestamp, _gasLimit, _gasPrice);
        bytes32 current = head;

        for (uint i = 0; i < length; i++) {
            if (_timestamp < objects[current].timestamp) {
                break;
            }

            current = toKey(objects[current]);
        }

        objects[id] = objects[current];
        objects[current] = Object(_address, _timestamp, _gasLimit, _gasPrice);
        length++;
    }

    function removeNext() internal {
        Object memory obj = getNext();
        delete objects[head];
        head = toKey(obj);
        length--;
    }

    function getNext() internal view returns (Object) {
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

            current = toKey(objects[current]);
            i++;
        }
    }
}
