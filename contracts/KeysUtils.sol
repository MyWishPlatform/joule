pragma solidity ^0.4.20;

library KeysUtils {
    // Such order is important to load from state
    struct Object {
        uint32 gasPrice;
        uint32 gasLimit;
        uint32 timestamp;
        address contractAddress;
    }

    function toKey(Object _obj) internal pure returns (bytes32) {
        return toKey(_obj.contractAddress, _obj.timestamp, _obj.gasLimit, _obj.gasPrice);
    }

    function toKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) internal pure returns (bytes32 result) {
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ - address (20 bytes)
        //                                                 ^^^^^^^^ - timestamp (4 bytes)
        //                                                         ^^^^^^^^ - gas limit (4 bytes)
        //                                                                 ^^^^^^^^ - gas price (4 bytes)
        assembly {
            result := or(result, mul(_address, 0x1000000000000000000000000))
            result := or(result, mul(and(_timestamp, 0xffffffff), 0x10000000000000000))
            result := or(result, mul(and(_gasLimit, 0xffffffff), 0x100000000))
            result := or(result, and(_gasPrice, 0xffffffff))
        }
    }

    function toMemoryObject(bytes32 _key, Object memory _dest) internal pure {
        assembly {
            mstore(_dest, and(_key, 0xffffffff))
            mstore(add(_dest, 0x20), and(div(_key, 0x100000000), 0xffffffff))
            mstore(add(_dest, 0x40), and(div(_key, 0x10000000000000000), 0xffffffff))
            mstore(add(_dest, 0x60), and(div(_key, 0x1000000000000000000000000), 0xffffffff))
        }
    }

    function toObject(bytes32 _key) internal pure returns (Object memory _dest) {
        toMemoryObject(_key, _dest);
    }

    function toStateObject(bytes32 _key, Object storage _dest) internal {
        assembly {
            sstore(_dest_slot, _key)
        }
    }

    function getTimestamp(bytes32 _key) internal pure returns (uint result) {
        assembly {
            result := and(div(_key, 0x10000000000000000), 0xffffffff)
        }
    }
}
