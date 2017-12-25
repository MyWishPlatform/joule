pragma solidity ^0.4.0;

contract Contract {

    function deposit() payable {
    }

    function withdraw(uint _value) {
        msg.sender.transfer(_value);
    }
}
