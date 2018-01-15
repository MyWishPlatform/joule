pragma solidity ^0.4.19;

import './JouleAPI.sol';
import './JouleContractHolder.sol';
import './CheckableContract.sol';

contract Joule is JouleAPI, JouleContractHolder {

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable {
        uint price = this.getPrice(_gasLimit, _gasPrice);
        require(msg.value >= price);

        require(_timestamp > now);
        require(_timestamp < 0x100000000);
        require(_gasLimit < MAX_GAS);
        // from 1 gwei to 0x100000000 gwei
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        insert(_address, _timestamp, getCorrectLimit(_gasLimit), _gasPrice / GWEI);

        if (msg.value > price) {
            msg.sender.transfer(msg.value - price);
        }
    }

    function getCorrectLimit(uint _gasLimit) internal view returns (uint) {
        return _gasLimit + IDLE_CALL;
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        require(_gasLimit < 4300000);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        return getCorrectLimit(_gasLimit) * _gasPrice;
    }

    function check() external {
        KeysUtils.Object memory current = KeysUtils.toObject(head);

        uint amount;
        while (current.timestamp != 0 && current.timestamp < now && msg.gas >= current.gasLimit) {
            uint gasBefore = msg.gas;
            bool status = current.contractAddress.call.gas(current.gasLimit)(0x919840ad);
            amount += current.gasLimit * current.gasPrice * GWEI;
            Checked(current.contractAddress, status, gasBefore - msg.gas);
            current = next();
        }
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
    }
}
