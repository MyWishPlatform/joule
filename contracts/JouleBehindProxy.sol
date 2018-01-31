pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './Joule.sol';
import './utils/TransferToken.sol';

contract JouleBehindProxy is Joule, Ownable, TransferToken {
    address public proxy;

    function JouleBehindProxy(JouleVault _vault, bytes32 _head, uint _length, JouleStorage _storage) public
        Joule (_vault, _head, _length, _storage) {
    }

    function setProxy(address _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    function register(address, uint, uint, uint) external payable returns (uint) {
        revert();
    }

    function registerFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public payable onlyProxy returns (uint) {
        return super.registerFor(_registrant, _address, _timestamp, _gasLimit, _gasPrice);
    }

    function invoke() public returns (uint) {
        revert();
    }

    function invokeOnce() public returns (uint) {
        revert();
    }


    function invokeFor(address _invoker) public onlyProxy returns (uint) {
        return super.invokeFor(_invoker);
    }

    function invokeOnceFor(address _invoker) public onlyProxy returns (uint) {
        return super.invokeOnceFor(_invoker);
    }

    function invokeCallback(address _contract, uint _gas) internal returns (bool) {
        return proxy.call.gas(_gas)(0x73027f6d, _contract);
    }
}
