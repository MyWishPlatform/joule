pragma solidity ^0.4.0;

import './JouleConsts.sol';

contract JouleContractHolder is usingConsts {

    struct Object {
        address contractAddress;
        uint32 timestamp;
        uint32 gasLimit;
        uint32 gasPrice;
    }

    uint public length = 0;
    bytes32 head = 0;
    mapping (bytes32 => Object) objects;

    function toKey(Object _obj) pure returns (bytes32) {
        return toKey(_obj.contractAddress, _obj.timestamp, _obj.gasLimit, _obj.gasPrice);
    }

    function toKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) pure returns (bytes32 result) {
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

    function insert(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external {
        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit < 4300000);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI); // from 1 gwei to 0x100000000 gwei
        insertInternal(_address, _timestamp, _gasLimit, _gasPrice / GWEI);
    }

    function insertInternal(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal {
        bytes32 id = toKey(_address, _timestamp, _gasLimit, _gasPrice);

        bytes32 current = head;
        bytes32 prev = 0;

        while (current != 0) {
            if (_timestamp < objects[current].timestamp) {
                break;
            }

            prev = current;
            current = toKey(objects[current]);
        }

        if (prev == 0) {
            head = id;
        } else {
            objects[prev].next = id;
            objects[id] = objects[prev];
        }

        Object memory object = Object(current, _address, _gasLimit, _timestamp);
        objects[id] = object;
        length++;
    }

    function removeNext() internal returns (Object) {
        Object memory obj = getNext();
        delete objects[head];
        head = toKey(obj);
        length--;
    }

    function getNext() internal view returns (Object) {
        return objects[head];
    }

    function getNext(uint count) external view returns (
        address[] addresses,
        uint32[] timestamps,
        uint32[] gasLimits,
        uint32[] gasPrices
    ) {
        addresses = new address[](count);
        timestamps = new uint32[](count);
        gasLimits = new uint32[](count);
        gasPrices = new uint32[](count);

        bytes32 current = head;
        uint i = 0;
        while (i < count && i < length) {
            addresses[i] = objects[current].contractAddress;
            timestamps[i] = objects[current].timestamp;
            gasLimits[i] = objects[current].gasLimit;
            gasPrices[i] = objects[current].gasPrice;

            current = toKey(objects[current]);
            i++;
        }
    }
}
