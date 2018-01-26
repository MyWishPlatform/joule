pragma solidity ^0.4.19;

contract usingConsts {
    uint constant GWEI = 0.001 szabo;
    // this two values influence to the reward price! do not change for already registered contracts!
    // remaining gas - amount of gas to finish transaction after invoke
    uint constant REMAINING_GAS = 10000;
    // idle gas - gas to joule (including proxy and others) invocation, excluding contract gas
    uint constant IDLE_GAS = REMAINING_GAS + 30000;

    uint constant MAX_GAS = 4000000;
    // Code version
    bytes8 constant VERSION = 0x01030025003336c6;
    //                          ^^ - major
    //                            ^^ - minor
    //                              ^^^^ - build
    //                                  ^^^^^^^^ - git hash
}
