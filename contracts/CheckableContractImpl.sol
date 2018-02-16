pragma solidity ^0.4.0;

import './CheckableContract.sol';

contract Contract0kGas is CheckableContract {

    function check() public {
        Checked();
    }
}

contract Contract100kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 1809; i++) {
        }
        Checked();
    }
}

contract Contract200kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 4134; i++) {
        }
        Checked();
    }
}

contract Contract300kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 6460; i++) {
        }
        Checked();
    }
}

contract Contract400kGas is CheckableContract {

    function check() public {
        for (uint i = 0; i < 8785; i++) {
        }
        Checked();
    }
}

contract ContractAllGas is CheckableContract {
    function check() public {
        revert();
    }
}