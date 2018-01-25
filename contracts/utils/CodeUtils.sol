pragma solidity ^0.4.0;

library CodeUtils {
    function hasCode(address _address) internal view returns (bool _result) {
        assembly { _result := gt(extcodesize(_address), 0x0) }
    }
}