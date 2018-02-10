pragma solidity ^0.4.0;

import './utils/Restriction.sol';

contract JouleStorage is Restriction {
    mapping(bytes32 => bytes32) map;

    function get(bytes32 _key) public view returns (bytes32 _value) {
        return map[_key];
    }

    function set(bytes32 _key, bytes32 _value) public restricted {
        map[_key] = _value;
    }

    function del(bytes32 _key) public restricted {
        delete map[_key];
    }

    function getAndDel(bytes32 _key) public restricted returns (bytes32 _value) {
        _value = map[_key];
        delete map[_key];
    }

    function swap(bytes32 _from, bytes32 _to) public restricted returns (bytes32 _value) {
        _value = map[_to];
        map[_to] = map[_from];
        delete map[_from];
    }
}
