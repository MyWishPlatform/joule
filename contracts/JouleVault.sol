pragma solidity ^0.4.0;

import 'zeppelin/ownership/Ownable.sol';

contract JouleVault is Ownable {
    address public joule;

    function setJoule(address _joule) public onlyOwner {
        joule = _joule;
    }

    modifier onlyJoule() {
        require(msg.sender == address(joule));
        _;
    }

    function withdraw(address _receiver, uint _amount) public onlyJoule {
        _receiver.transfer(_amount);
    }

    function () public payable {

    }
}
