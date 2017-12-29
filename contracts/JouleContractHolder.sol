pragma solidity ^0.4.0;

import 'ethereum-datetime/contracts/DateTime.sol';

contract JouleContractHolder {

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

    function toKey(address _address, uint _gasLimit, uint _timestamp) constant returns (bytes32 result) {
        var (year, month, day, hour, minute) = decomposeTimestamp(_timestamp);
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_timestamp, 0x1000000000000000000000000000000000000000000000000))
            result := or(result, mul(_address, 0x1000000000))
            result := or(result, _gasLimit)
        }
    }

    function insert(address _address, uint _gasLimit, uint _timestamp) {
        require(_timestamp > now);
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
