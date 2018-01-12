pragma solidity ^0.4.0;

import './CheckableContract.sol';

contract Contract100kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 1827; i++) {
        }
    }
}

contract Contract200kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 4152; i++) {
        }
    }
}

contract Contract300kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 6478; i++) {
        }
    }
}

contract Contract400kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 8803; i++) {
        }
    }
}