pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "ethereum-alarm-clock/contracts/TimestampScheduler.sol";
import "./JouleContractHolder.sol";
import "./Contract.sol";

contract Joule is JouleContractHolder, Ownable {

    TimestampScheduler constant scheduler  = TimestampScheduler(address(this));

    function Joule() {
    }

    function registerContract(address _contractAddress, uint64 _executionDate) payable {
        hold(_contractAddress, _executionDate);
//        _contractAddress.transfer(msg.value);

        scheduler.call(
            _contractAddress,
            bytes4(sha3(_methodSignature)),
            sha3(),
            255
        );
    }

    function executeContract(address _contractAddress, string _methodSignature) {
        launch(_contractAddress, _methodSignature);
    }
}
