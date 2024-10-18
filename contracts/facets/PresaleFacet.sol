// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PresaleFacet is Ownable, ReentrancyGuard {
    uint256 public constant PRICE_PER_TOKEN = 0.033333333333333333 ether;
    uint256 public constant MIN_PURCHASE = 0.01 ether;

    bool public presaleActive = false;

    event TokensPurchased(address indexed buyer, uint256 amount);

    function setPresaleActive(bool _active) external onlyOwner {
        presaleActive = _active;
    }

    function buyTokens() external payable nonReentrant {
        require(presaleActive, "Presale is not active");
        require(msg.value >= MIN_PURCHASE, "Below minimum purchase amount");

        uint256 tokenAmount = msg.value / PRICE_PER_TOKEN;
        require(tokenAmount > 0, "Not enough ETH sent");

        
        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}