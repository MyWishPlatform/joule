pragma solidity ^0.4.0;

import 'ethereum-datetime/contracts/DateTime.sol';

contract JouleContractHolder {
    //       year             month            day              hour            minute   contracts
    mapping (uint => mapping (uint => mapping (uint => mapping (uint => mapping (uint => address[]))))) internal store;
    uint internal count = 0;

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

    function insert(address _e, uint _timestamp) {
        require(_timestamp > now);
        var (year, month, day, hour, minute) = decomposeTimestamp(_timestamp);
        store[year][month][day][hour][minute].push(_e);
        count++;
    }

    function getForTimestamp(uint _timestamp) returns (address[]) {
        var (year, month, day, hour, minute) = decomposeTimestamp(_timestamp);
        return store[year][month][day][hour][minute];
    }

    function getNext() constant returns (address[] _addresses, uint _timestamp) {
        _timestamp = now;

        while (count > 0) {
            _addresses = getForTimestamp(_timestamp);
            if (_addresses.length > 0) {
                break;
            }
            _timestamp += 1 minutes;
        }
    }
}
