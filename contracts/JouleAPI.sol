pragma solidity ^0.4.19;

contract JouleAPI {
    event Checked(address indexed _address, bool _status, uint _usedGas);

    /**
     * @dev Registers the specified contract to invoke at the specified time with the specified gas and price.
     * @notice It required amount of ETH as value, to cover gas usage. See getPrice method.
     *
     * @param _address Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     */
    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable;

    /**
     * @dev Invokes next contracts in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     */
    function invoke() external;

    /**
     * @dev Invokes the top contract in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     */
    function invokeTop() external;

    /**
     * @dev Calculates required to register amount of WEI.
     *
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     * @return Amount in wei.
     */
    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint);

    /**
     * @dev Gets top contract (the next to invoke).
     *
     * @return contractAddress  The contract address.
     * @return timestamp        The invocation timestamp.
     * @return gasLimit         The invocation maximum gas.
     * @return gasPrice         The invocation expected price.
     */
    function getTop() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice
    );

    /**
     * @dev Gets top _count contracts (in order to invoke).
     *
     * @return addresses    The contracts addresses.
     * @return timestamps   The invocation timestamps.
     * @return gasLimits    The invocation gas limits.
     * @return gasPrices    The invocation expected prices.
     */
    function getTop(uint _count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices
    );
}
