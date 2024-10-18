// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../libraries/LibDiamond.sol";

contract MerkleFacet {
    event Claimed(address indexed claimant, uint256 amount);

    function setMerkleRoot(bytes32 _merkleRoot) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondStorage().merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(!ds.claimed[msg.sender], "Address already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(_merkleProof, ds.merkleRoot, leaf), "Invalid proof");

        ds.claimed[msg.sender] = true;
        emit Claimed(msg.sender, _amount);
    }
}