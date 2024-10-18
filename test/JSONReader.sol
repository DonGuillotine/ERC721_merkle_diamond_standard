// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";

contract JSONReader {
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function readJSONFile(string memory _path) internal returns (string memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "cat";
        inputs[1] = _path;

        bytes memory result = vm.ffi(inputs);
        return string(result);
    }
}