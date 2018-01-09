pragma solidity ^0.4.0;

contract JouleIndex {
    // year -> month -> day -> hour
    mapping (bytes32 => bytes32) index;

    function JouleIndex() {

    }

    function insert(uint _timestamp, bytes32 _key) {
        bytes32 tsKey = toKey(_timestamp);
        if (index[tsKey] != 0) {
            return;
        }

        bytes32 year = toKey(_timestamp, 1 years);
        bytes32 week = toKey(_timestamp, 1 weeks);
        bytes32 hour = toKey(_timestamp, 1 hours);
        bytes32 minute = toKey(_timestamp, 1 minutes);
        if (index[year] < week) {
            index[year] = week;
        }
        if (index[week] < hour) {
            index[week] = hour;
        }
        if (index[hour] < minute) {
            index[hour] = minute;
        }
        bytes32 lastKey = index[minute];
        bytes32 prevKey = 0;
        while (lastKey > tsKey) {
            prevKey = lastKey;
            lastKey = index[lastKey];
        }
        if (prevKey == 0) {
            index[minute] = tsKey;
        }
        else {
            index[prevKey] = tsKey;
        }
        index[tsKey] = lastKey;
    }

    function findFloor(uint _timestamp) returns (uint) {

    }

    function toKey(uint timestamp, uint rounder) view returns (bytes32) {
        return bytes32(timestamp / rounder * rounder);
    }


    function toKey(uint timestamp) view returns (bytes32) {
        return bytes32(timestamp);
    }
}
