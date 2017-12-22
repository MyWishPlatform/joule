pragma solidity ^0.4.0;

import './JouleContractLauncher.sol';

contract JouleContractHolder is JouleContractLauncher {

    mapping (address => uint64) internal roots;
    mapping (bytes32 => uint64) internal chains;

    event Hold(address indexed c, uint64 until);

    function getExecutionDate(address _contractAddress, uint _index) public constant returns (uint64 _executionDate) {
        uint64 executionDate = roots[_contractAddress];
        for (uint i = 0; i < _index; i++) {
            executionDate = chains[toKey(_contractAddress, executionDate)];
        }
        return executionDate;
    }

    function launch(address _contractAddress, string _methodSignature) public {
        uint64 head = roots[_contractAddress];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(_contractAddress, head);

        uint64 next = chains[currentKey];

        super.launch(_contractAddress, _methodSignature);

        if (next == 0) {
            delete roots[_contractAddress];
        }
        else {
            roots[_contractAddress] = next;
        }
        Launch(_contractAddress);
    }

    function toKey(address _contractAddress, uint _launchDate) internal constant returns (bytes32 result) {
        // WISH masc to increase entropy
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_contractAddress, 0x10000000000000000))
            result := or(result, _launchDate)
        }
    }

    function hold(address _contractAddress, uint64 _executionDate) internal {
        require(_executionDate > block.timestamp);
        uint64 head = roots[_contractAddress];

        if (head == 0) {
            roots[_contractAddress] = _executionDate;
            return;
        }

        bytes32 headKey = toKey(_contractAddress, head);
        uint parent;
        bytes32 parentKey;

        while (head != 0 && _executionDate > head) {
            parent = head;
            parentKey = headKey;

            head = chains[headKey];
            headKey = toKey(_contractAddress, head);
        }

        if (_executionDate == head) {
            return;
        }

        if (head != 0) {
            chains[toKey(_contractAddress, _executionDate)] = head;
        }

        if (parent == 0) {
            roots[_contractAddress] = _executionDate;
        }
        else {
            chains[parentKey] = _executionDate;
        }

        Hold(_contractAddress, _executionDate);
    }
}
