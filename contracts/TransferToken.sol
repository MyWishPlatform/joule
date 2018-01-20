pragma solidity ^0.4.19;

import 'zeppelin/ownership/Ownable.sol';
import 'zeppelin/token/ERC20Basic.sol';

contract TransferToken is Ownable {
    function transferToken(ERC20Basic _token, address _to, uint _value) public onlyOwner {
        _token.transfer(_to, _value);
    }
}
