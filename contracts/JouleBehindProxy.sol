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

    function invoke() public onlyProxy returns (uint) {
        return super.invoke();
    }

    function invokeTop() public onlyProxy returns (uint) {
        return super.invokeTop();
    }

    function invokeCallback(address _contract, uint _gas) internal returns (bool) {
        return proxy.call.gas(_gas)(0x73027f6d, _contract);
    }
}
