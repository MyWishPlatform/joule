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
}
