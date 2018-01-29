pragma solidity ^0.4.19;

contract JouleAPI {
    event Invoked(address indexed _address, bool _status, uint _usedGas);
    event Registered(address indexed _registrant, address indexed _address, uint _timestamp, uint _gasLimit, uint _gasPrice);

    /**
     * @dev Registers the specified contract to invoke at the specified time with the specified gas and price.
     * @notice It required amount of ETH as value, to cover gas usage. See getPrice method.
     *
     * @param _address Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     * @return Amount of change.
     */
    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint);

    /**
     * @dev Invokes next contracts in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @return Reward amount.
     */
    function invoke() public returns (uint);

    /**
     * @dev Invokes the top contract in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @return Reward amount.
     */
    function invokeOnce() public returns (uint);

    /**
     * @dev Calculates required to register amount of WEI.
     *
     * @param _gasLimit Gas which will be posted to call.
     * @param _gasPrice Gas price which is recommended to use for this invocation.
     * @return Amount in wei.
     */
    function getPrice(uint _gasLimit, uint _gasPrice) external view returns (uint);

    /**
     * @dev Gets how many contracts are registered (and not invoked).
     */
    function getCount() public view returns (uint);

    /**
     * @dev Gets top contract (the next to invoke).
     *
     * @return contractAddress  The contract address.
     * @return timestamp        The invocation timestamp.
     * @return gasLimit         The contract gas.
     * @return gasPrice         The invocation expected price.
     * @return invokeGas        The minimal amount of gas to invoke (including gas for joule).
     * @return rewardAmount     The amount of reward for invocation.
     */
    function getTopOnce() external view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice,
        uint invokeGas,
        uint rewardAmount
    );

    /**
     * @dev Gets the next contract by the specified previous in order to invoke.
     *
     * @param _contractAddress  The previous contract address.
     * @param _timestamp        The previous invocation timestamp.
     * @param _gasLimit         The previous invocation maximum gas.
     * @param _gasPrice         The previous invocation expected price.
     * @return contractAddress  The contract address.
     * @return gasLimit         The contract gas.
     * @return gasPrice         The invocation expected price.
     * @return invokeGas        The minimal amount of gas to invoke (including gas for joule).
     * @return rewardAmount     The amount of reward for invocation.
     */
    function getNext(address _contractAddress,
                     uint _timestamp,
                     uint _gasLimit,
                     uint _gasPrice) public view returns (
        address contractAddress,
        uint timestamp,
        uint gasLimit,
        uint gasPrice,
        uint invokeGas,
        uint rewardAmount
    );

    /**
     * @dev Gets top _count contracts (in order to invoke).
     *
     * @param _count            How many records will be returned.
     * @return addresses        The contracts addresses.
     * @return timestamps       The invocation timestamps.
     * @return gasLimits        The contract gas.
     * @return gasPrices        The invocation expected price.
     * @return invokeGases      The minimal amount of gas to invoke (including gas for joule).
     * @return rewardAmounts    The amount of reward for invocation.
     */
    function getTop(uint _count) external view returns (
        address[] addresses,
        uint[] timestamps,
        uint[] gasLimits,
        uint[] gasPrices,
        uint[] invokeGases,
        uint[] rewardAmounts
    );

    /**
     * @dev Gets actual code version.
     * @return Code version. Mask: 0xff.0xff.0xffff-0xffffffff (major.minor.build-hash)
     */
    function getVersion() external view returns (bytes8);
}
