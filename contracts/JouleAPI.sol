pragma solidity ^0.4.0;

contract JouleAPI {

    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable;

    function check() external;

    function getNext(uint count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices
    );
}
