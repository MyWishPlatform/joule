pragma solidity ^0.4.0;

contract JouleContractLauncher {

    event Launch(address indexed c /* todo: executor address and, maybe, method parameters */);

    function launch(address _contractAddress, string _methodSignature) {

        Launch(_contractAddress);
    }
}
