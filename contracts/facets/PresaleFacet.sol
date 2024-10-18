// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract PresaleFacet {
    uint256 public constant PRICE_PER_TOKEN = 0.033333333333333333 ether;
    uint256 public constant MIN_PURCHASE = 0.01 ether;

    event TokensPurchased(address indexed buyer, uint256 amount);

    function setPresaleActive(bool _active) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondStorage().presaleActive = _active;
    }

    function buyTokens() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.presaleActive, "Presale is not active");
        require(msg.value >= MIN_PURCHASE, "Below minimum purchase amount");

        uint256 tokenAmount = msg.value / PRICE_PER_TOKEN;
        require(tokenAmount > 0, "Not enough ETH sent");

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function withdrawFunds() external {
        LibDiamond.enforceIsContractOwner();
        payable(LibDiamond.contractOwner()).transfer(address(this).balance);
    }
}