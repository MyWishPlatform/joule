pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import './Joule.sol';
import './JouleIAPI.sol';
import './TransferToken.sol';

contract JouleBehindProxy is Joule, JouleIAPI, Ownable, TransferToken {
    address public proxy;

    function setProxy(address _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    function invokeFromProxy() external onlyProxy returns (uint _amount) {
        return innerInvoke(innerCallback);
    }

    function invokeTopFromProxy() external onlyProxy returns (uint _amount) {
        return innerInvokeTop(innerCallback);
    }

    function innerCallback(address _addr, uint _gas) internal returns (bool) {
        return proxy.call.gas(_gas)(0xabcdef00, _addr);
    }
}
