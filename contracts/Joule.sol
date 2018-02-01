pragma solidity ^0.4.19;

import './JouleCore.sol';
import './JouleAPI.sol';

contract Joule is JouleAPI, JouleCore {
    function Joule(JouleVault _vault, bytes32 _head, uint _length, JouleStorage _storage) public
        JouleCore(_head, _length, _storage) {
    }

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint) {
        Registered(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
        return innerRegister(msg.sender, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function registerFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public payable returns (uint) {
        Registered(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
        return innerRegister(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function unregister(bytes32 _key, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external returns (uint) {
        Unregistered(msg.sender, _address, _timestamp, _gasLimit, _gasPrice);
        return innerUnregister(msg.sender, _key, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function invoke() public returns (uint) {
        return innerInvoke(msg.sender, invokeCallback);
    }

    function invokeFor(address _invoker) public returns (uint) {
        return innerInvoke(_invoker, invokeCallback);
    }

    function invokeOnce() public returns (uint) {
        return innerInvokeOnce(msg.sender, invokeCallback);
    }

    function invokeOnceFor(address _invoker) public returns (uint) {
        return innerInvokeOnce(_invoker, invokeCallback);
    }

    function invokeCallback(address _invoker, KeysUtils.Object memory _record) internal returns (bool) {
        uint gas = msg.gas;
        bool status = super.invokeCallback(_record);
        Invoked(_invoker, _record.contractAddress, status, gas - msg.gas);
        return status;
    }
}
