pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TimestampScheduler.sol";
import "./RequestTracker.sol";
import "./RequestFactory.sol";

import "./JouleContractHolder.sol";
import "./contracts/Contract.sol";
import "./contracts/SomeContract1.sol";
import "./contracts/SomeContract2.sol";
import "./JouleConsts.sol";

contract Joule is usingConsts, JouleContractHolder, Ownable {

    RequestTracker constant requestTracker = new RequestTracker();
    RequestFactory constant requestFactory = new RequestFactory(requestTracker);
    TimestampScheduler constant scheduler = new TimestampScheduler(requestFactory);

    enum ContractType {SOME1, SOME2}

    function Joule() {
    }

    function registerContract(ContractType _type, uint _executionDate) returns(address _contractAddress) {
        require(msg.value >= CONTRACT_PRICE_WEI);

        Contract c;
        if (_type == ContractType.SOME1) {
            c = new SomeContract1();
        }
        else if (_type == ContractType.SOME2) {
            c = new SomeContract2();
        }

        uint[7] memory args = [
            0,
            0,
            255,
            _executionDate,
            200000,
            0,
            0
        ];
        scheduler.scheduleTransaction(_contractAddress, bytes4(sha3("execute()")), args);
    }

    function deposit(address _contractAddress) payable {
        Contract(_contractAddress).deposit();
    }

    function withdraw(address _contractAddress, uint _value) {
        Contract(_contractAddress).withdraw(_value);
    }
}
