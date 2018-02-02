pragma solidity ^0.4.19;

import './JouleConsts.sol';
import './JouleIndex.sol';
import './JouleStorage.sol';

contract JouleContractHolder is usingConsts {
    using KeysUtils for bytes32;
//    event Found(uint timestamp);
    uint internal length;
    bytes32 public head;
    JouleStorage public state;
    JouleIndex public index;

    function JouleContractHolder(bytes32 _head, uint _length, JouleStorage _storage) public {
        index = new JouleIndex(_storage);
        state = _storage;
        head = _head;
        length = _length;
    }

    function insert(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal {
        length ++;
        bytes32 id = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        if (head == 0) {
            head = id;
            index.insert(id);
//            Found(0xffffffff);
            return;
        }
        bytes32 previous = index.findFloorKey(_timestamp);

        // reject duplicate key on the end
        require(previous != id);
        // reject duplicate in the middle
        require(state.get(id) == 0);

        uint prevTimestamp = previous.getTimestamp();
//        Found(prevTimestamp);
        uint headTimestamp = head.getTimestamp();
        // add as head, prevTimestamp == 0 or in the past
        if (prevTimestamp < headTimestamp) {
            state.set(id, head);
            head = id;
        }
        // add after the previous
        else {
            state.set(id, state.get(previous));
            state.set(previous, id);
        }
        index.insert(id);
    }

    function updateGas(bytes32 _key, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice, uint _newGasLimit) internal {
        bytes32 id = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        bytes32 newId = KeysUtils.toKey(_address, _timestamp, _newGasLimit, _gasPrice);
        if (id == head) {
            bytes32 afterHead = state.get(id);
            head = newId;
            state.set(newId, afterHead);
            return;
        }

        require(state.get(_key) == id);
        state.set(_key, newId);
        bytes32 afterUpdate = state.get(id);
        state.set(newId, afterUpdate);
        index.update(id, newId);
    }

    function next() internal returns (KeysUtils.Object memory _next) {
        head = state.get(head);
        length--;
        _next = head.toObject();
    }

    function getCount() public view returns (uint) {
        return length;
    }

    function getRecord(bytes32 _parent) internal view returns (bytes32 _record) {
        if (_parent == 0) {
            _record = head;
        }
        else {
            _record = state.get(_parent);
        }
    }

    /**
     * @dev Find previous key for existing value.
     */
    function findPrevious(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal view returns (bytes32) {
        bytes32 target = KeysUtils.toKey(_address, _timestamp, _gasLimit, _gasPrice);
        if (target == head) {
            return 0;
        }
        if (target.getTimestamp() == head.getTimestamp()) {
            return head;
        }
        bytes32 previous = index.findFloorKey(_timestamp - 1);
        bytes32 current = state.get(previous);
        while (current != target) {
            previous = current;
            current = state.get(previous);
        }
        return previous;
    }
}
