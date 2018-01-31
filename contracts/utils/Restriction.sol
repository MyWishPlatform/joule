pragma solidity ^0.4.19;

contract Restriction {
    mapping (address => bool) internal accesses;

    function Restriction() public {
        accesses[msg.sender] = true;
    }

    function giveAccess(address _addr) public restricted {
        accesses[_addr] = true;
    }

    function removeAccess(address _addr) public restricted {
        delete accesses[_addr];
    }

    function hasAccess() public constant returns (bool) {
        return accesses[msg.sender];
    }

    modifier restricted() {
        require(hasAccess());
        _;
    }
}
