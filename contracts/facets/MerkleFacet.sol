// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleFacet is Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    event Claimed(address indexed claimant, uint256 amount);

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        require(!claimed[msg.sender], "Address already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

        claimed[msg.sender] = true;
        emit Claimed(msg.sender, _amount);
    }
}