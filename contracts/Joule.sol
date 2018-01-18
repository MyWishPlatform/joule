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

        insert(_address, _timestamp, _gasLimit, _gasPrice / GWEI);

        Registered(_address, _timestamp, _gasLimit, _gasPrice);

        if (msg.value > price) {
            msg.sender.transfer(msg.value - price);
        }
    }

    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint) {
        require(_gasLimit < 4300000);
        require(_gasPrice > GWEI);
        require(_gasPrice < 0x100000000 * GWEI);

        return getPriceInner(_gasLimit, _gasPrice);
    }

    function getPriceInner(uint _gasLimit, uint _gasPrice) internal pure returns (uint) {
        return (_gasLimit + IDLE_GAS) * _gasPrice;
    }

    function invoke() external {
        KeysUtils.Object memory current = KeysUtils.toObject(head);

        uint amount;
        while (current.timestamp != 0 && current.timestamp < now && msg.gas >= current.gasLimit) {
            uint gas = msg.gas;
            bool status = current.contractAddress.call.gas(current.gasLimit)(0x919840ad);
            gas -= msg.gas;
            Invoked(current.contractAddress, status, gas);

            amount += getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);
            current = next();
        }
        if (amount > 0) {
            msg.sender.transfer(amount);
        }
    }

    function invokeTop() external {
        KeysUtils.Object memory current = KeysUtils.toObject(head);
        uint gas = msg.gas;
        bool status = current.contractAddress.call.gas(current.gasLimit)(0x919840ad);
        gas -= msg.gas;

        Invoked(current.contractAddress, status, gas);

        uint amount = getPriceInner(current.gasLimit, current.gasPriceGwei * GWEI);

        if (amount > 0) {
            msg.sender.transfer(amount);
        }
    }
}
