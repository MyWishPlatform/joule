pragma solidity ^0.4.19;

contract usingConsts {
    uint constant GWEI = 0.001 szabo;
    // this value influence to the reward price! do not change for already registered contracts!
    uint constant IDLE_GAS = 25000;
    uint constant MAX_GAS = 4000000;
    // Code version
    bytes8 constant VERSION = 0x0100001300000000;
    //                        ^^ - major
    //                          ^^ - minor
    //                            ^^^^ - build
    //                                ^^^^^^^^ - git hash
}
