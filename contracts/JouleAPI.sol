pragma solidity ^0.4.0;

contract JouleAPI {

    function insert(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external;

    function check() payable;

    function getNext(uint count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices
    );
}
