pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './JouleCore.sol';
import './utils/TransferToken.sol';

contract JouleBehindProxy is JouleCore, Ownable, TransferToken {
    address public proxy;

    function JouleBehindProxy(JouleVault _vault, bytes32 _head, uint _length, JouleStorage _storage) public
        JouleCore(_vault, _head, _length, _storage) {
    }

    function setProxy(address _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    function registerFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public payable onlyProxy returns (uint) {
        return innerRegister(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function unregisterFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public onlyProxy returns (uint) {
        return innerUnregister(_registrant, _key, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function invokeFor(address _invoker) public onlyProxy returns (uint) {
        return innerInvoke(_invoker);
    }

    function invokeOnceFor(address _invoker) public onlyProxy returns (uint) {
        return innerInvokeOnce(_invoker);
    }

    function invokeCallback(address _invoker, KeysUtils.Object memory _record) internal returns (bool) {
        return callback(_invoker, _record.contractAddress, _record.timestamp, _record.gasLimit, _record.gasPrice);
    }
}
