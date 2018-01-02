pragma solidity ^0.4.0;

import 'ethereum-datetime/contracts/DateTime.sol';
import './JouleConsts.sol';

contract JouleContractHolder is usingConsts {

    DateTime internal dt = new DateTime();

    function decomposeTimestamp(uint _timestamp) constant returns (uint16, uint8, uint8, uint8, uint8) {
        return (
            dt.getYear(_timestamp),
            dt.getMonth(_timestamp),
            dt.getDay(_timestamp),
            dt.getHour(_timestamp),
            dt.getMinute(_timestamp)
        );
    }

    struct Object {
        bytes32 next;
        address contractAddress;
        uint gasLimit;
        uint timestamp;
    }

    uint public length = 0;
    bytes32 public head = 0;
    mapping (bytes32 => Object) public objects;

    function toKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) pure returns (bytes32 result) {
        var (year, month, day, hour, minute) = decomposeTimestamp(_timestamp);
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
        bytes32 id = toKey(_address, _gasLimit, _timestamp);

        bytes32 current = head;
        bytes32 prev = 0;

        while (current != 0) {
            if (_timestamp < objects[current].timestamp) {
                break;
            }

            prev = current;
            current = objects[current].next;
        }

        if (prev == 0) {
            head = id;
        } else {
            objects[prev].next = id;
        }

        Object memory object = Object(current, _address, _gasLimit, _timestamp);
        objects[id] = object;
        length++;
    }

    function getNext() constant returns (address _contract, uint _gasLimit, uint _timestamp) {
        if (head != 0) {
            Object object = objects[head];
            _contract = object.contractAddress;
            _gasLimit = object.gasLimit;
            _timestamp = object.timestamp;
        }
    }

    function total() constant returns (address[] addresses, uint[] gasLimits, uint[] timestamps) {
        addresses = new address[](length);
        gasLimits = new uint[](length);
        timestamps = new uint[](length);

        bytes32 current = head;
        uint i = 0;
        while (current != 0) {
            addresses[i] = objects[current].contractAddress;
            gasLimits[i] = objects[current].gasLimit;
            timestamps[i] = objects[current].timestamp;

            current = objects[current].next;
            i++;
        }
    }
}
