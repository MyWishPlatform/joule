pragma solidity ^0.4.19;

contract JouleAPI {
    event Invoked(address indexed _invoker, address indexed _address, bool _status, uint _usedGas);
    event Registered(address indexed _registrant, address indexed _address, uint _timestamp, uint _gasLimit, uint _gasPrice);
    event Unregistered(address indexed _registrant, address indexed _address, uint _timestamp, uint _gasLimit, uint _gasPrice, uint _amount);

    /**
     * @dev Registers the specified contract to invoke at the specified time with the specified gas and price.
     * @notice Registration requires the specified amount of ETH in value, to cover invoke bonus. See getPrice method.
     *
     * @param _address      Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp    Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit     Gas which will be posted to call.
     * @param _gasPrice     Gas price which is recommended to use for this invocation.
     * @return Amount of change.
     */
    function register(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external payable returns (uint);

    /**
     * @dev Registers the specified contract to invoke at the specified time with the specified gas and price.
     * @notice Registration requires the specified amount of ETH in value, to cover invoke bonus. See getPrice method.
     * @notice If value would be more then required (see getPrice) change will be returned to msg.sender (not to _registrant!).
     *
     * @param _registrant   Any address which will be owners for this registration. Only he can unregister. Useful for calling from contract.
     * @param _address      Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp    Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit     Gas which will be posted to call.
     * @param _gasPrice     Gas price which is recommended to use for this invocation.
     * @return Amount of change.
     */
    function registerFor(address _registrant, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public payable returns (uint);

    /**
     * @dev Remove registration of the specified contract (with exact parameters) by the specified key. See findKey method for looking for key.
     * @notice It returns not full amount of ETH.
     * @notice Only registrant can remove their registration.
     * @notice Only registrations in future can be removed.
     *
     * @param _key          Contract key, to fast finding during unregister. See findKey method for getting key.
     * @param _address      Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp    Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit     Gas which will be posted to call.
     * @param _gasPrice     Gas price which is recommended to use for this invocation.
     * @return Amount of refund.
     */
    function unregister(bytes32 _key, address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) external returns (uint);

    /**
     * @dev Invokes next contracts in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @return Reward amount.
     */
    function invoke() public returns (uint);

    /**
     * @dev Invokes next contracts in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @param _invoker Any address from which event will be threw. Useful for calling from contract.
     * @return Reward amount.
     */
    function invokeFor(address _invoker) public returns (uint);

    /**
     * @dev Invokes the top contract in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @return Reward amount.
     */
    function invokeOnce() public returns (uint);

    /**
     * @dev Invokes the top contract in the queue.
     * @notice Eth amount to cover gas will be returned if gas price is equal or less then specified for contract. Check getTop for right gas price.
     * @param _invoker Any address from which event will be threw. Useful for calling from contract.
     * @return Reward amount.
     */
    function invokeOnceFor(address _invoker) public returns (uint);

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
     * @dev Finds key for the registration with exact parameters. Be careful, key might be changed because of other registrations.
     * @param _address      Contract's address. Contract MUST implements Checkable interface.
     * @param _timestamp    Timestamp at what moment contract should be called. It MUST be in future.
     * @param _gasLimit     Gas which will be posted to call.
     * @param _gasPrice     Gas price which is recommended to use for this invocation.
     * @return _key         Key of the specified registration.
     */
    function findKey(address _address, uint _timestamp, uint _gasLimit, uint _gasPrice) public view returns (bytes32);

    /**
     * @dev Gets actual code version.
     * @return Code version. Mask: 0xff.0xff.0xffff-0xffffffff (major.minor.build-hash)
     */
    function getVersion() external view returns (bytes8);
}
