pragma solidity ^0.4.19;

contract usingConsts {
    uint constant GWEI = 0.001 szabo;
    // this two values influence to the reward price! do not change for already registered contracts!
    // remaining gas - amount of gas to finish transaction after invoke
    uint constant REMAINING_GAS = 10000;
    // idle gas - gas to joule (including proxy and others) invocation, excluding contract gas
    uint constant IDLE_GAS = REMAINING_GAS + 30000;
    // not, it mist be less then 0x00ffffff, because high bytes is used for storing flags
    uint constant MAX_GAS = 4000000;
    // key flag for storing owner
    uint constant OWNER_FLAG = 0x01000000;
    // Code version
    bytes8 constant VERSION = 0x0106003c01bcd26e;
    //                          ^^ - major
    //                            ^^ - minor
    //                              ^^^^ - build
    //                                  ^^^^^^^^ - git hash
}
