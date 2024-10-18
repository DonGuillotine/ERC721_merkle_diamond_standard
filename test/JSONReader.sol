// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract JSONReader is Test {
    function readJSONFile(string memory _path) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory fullPath = string(abi.encodePacked(root, "/", _path));
        return vm.readFile(fullPath);
    }
}