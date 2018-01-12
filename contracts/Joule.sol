pragma solidity ^0.4.0;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';

contract Joule is JouleAPI, JouleContractHolder {

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable {
        require(msg.value >= _gasLimit * _gasPrice);

        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit < 4300000);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI); // from 1 gwei to 0x100000000 gwei

        insert(_address, uint32(_timestamp), uint32(_gasLimit), uint32(_gasPrice / GWEI));

        if (msg.value > _gasLimit * _gasPrice) {
            msg.sender.transfer(msg.value - _gasLimit * _gasPrice);
        }
    }

    function check() external {
        while (length > 0) {
            KeysUtils.Object memory next = getNext();
            if (next.timestamp > now || msg.gas < next.gasLimit) {
                break;
            }

            CheckableContract(next.contractAddress).check();
            removeNext();
        }
    }
}
