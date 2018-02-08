pragma solidity ^0.4.19;

import "./utils/KeysUtils.sol";
import './JouleStorage.sol';
import './JouleIndexCore.sol';
import 'zeppelin/ownership/Ownable.sol';

contract JouleIndex is JouleIndexCore, Ownable  {
    using KeysUtils for bytes32;

    function JouleIndex(JouleStorage _storage) public
            JouleIndexCore(_storage) {
        state = _storage;
    }

    function insert(bytes32 _key) public onlyOwner {
        insertIndex(_key);
    }

    /**
     * @dev Update key value from the previous state to new. Timestamp MUST be the same on both keys.
     */
    function update(bytes32 _prev, bytes32 _key) public onlyOwner {
        updateIndex(_prev, _key);
    }

    function findFloorKey(uint _timestamp) view public returns (bytes32) {
        return findFloorKeyIndex(_timestamp);
    }
}
