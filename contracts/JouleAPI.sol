pragma solidity ^0.4.19;

import "./KeysUtils.sol";

contract JouleAPI {
    event Checked(address indexed _address, bool _status, uint _usedGas);

    /**
     * @dev Registers the specified contract to invoke at the specified time with the specified gas and price.
     *      It required amount of ETH as value, to cover gas usage. See getPrice method.
     * @param _address Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     */
    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable;

    function check() external;

    /**
     * @dev Calculates required to register amount of WEI.
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     */
    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint);

    function getNext(uint _count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices
    );
}
