pragma solidity ^0.4.0;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';

contract Joule is JouleAPI, JouleContractHolder {

    function Joule() {}

    function check() payable {
        uint remainingGas = msg.value;
        while (length != 0) {
            Object memory next = getNext();
            if (remainingGas < next.gasLimit) {
                break;
            }
            CheckableContract(next.contractAddress).check.value(next.gasLimit * next.gasPrice)();
            remainingGas -= next.gasLimit * next.gasPrice;
        }
    }
}
