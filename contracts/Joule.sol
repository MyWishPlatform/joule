pragma solidity ^0.4.0;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';

contract Joule is JouleAPI, JouleContractHolder {

    function check(uint gasToSpend) external {
        uint remainingGas = gasToSpend;
        while (length > 0) {
            Object memory next = getNext();
            if (remainingGas < next.gasLimit * next.gasPrice * GWEI) {
                break;
            }
            CheckableContract(next.contractAddress).check();
            removeNext();
            remainingGas -= (next.gasLimit * next.gasPrice * GWEI);
        }
    }
}
