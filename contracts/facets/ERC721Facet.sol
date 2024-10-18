// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/LibDiamond.sol";

contract ERC721Facet {
    using Counters for Counters.Counter;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function initialize(string memory _name, string memory _symbol, uint256 _maxSupply) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(bytes(ds.name).length == 0, "ERC721: Already initialized");
        ds.name = _name;
        ds.symbol = _symbol;
        ds.maxSupply = _maxSupply;
    }

    function name() public view returns (string memory) {
        return LibDiamond.diamondStorage().name;
    }

    function symbol() public view returns (string memory) {
        return LibDiamond.diamondStorage().symbol;
    }

    function mint(address to) public {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.tokenIds.current() < ds.maxSupply, "Max supply reached");
        ds.tokenIds.increment();
        uint256 newTokenId = ds.tokenIds.current();
        _safeMint(to, newTokenId);
    }

    function totalSupply() public view returns (uint256) {
        return LibDiamond.diamondStorage().tokenIds.current();
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return LibDiamond.diamondStorage().balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = LibDiamond.diamondStorage().owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.owners[tokenId] == address(0), "ERC721: token already minted");

        ds.balances[to] += 1;
        ds.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
