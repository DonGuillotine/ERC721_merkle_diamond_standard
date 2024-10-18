// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import { ERC721Facet } from "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/MerkleFacet.sol";
import "../contracts/facets/PresaleFacet.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondTest is Test, DiamondUtils, IERC721Receiver {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC721Facet erc721Facet;
    MerkleFacet merkleFacet;
    PresaleFacet presaleFacet;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        // Deploy DiamondCutFacet
        diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        diamond = new Diamond(address(this), address(diamondCutFacet));

        // Deploy facets
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        erc721Facet = new ERC721Facet();
        merkleFacet = new MerkleFacet();
        presaleFacet = new PresaleFacet();

        // Add facets to Diamond
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC721Facet")
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(merkleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("MerkleFacet")
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(presaleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("PresaleFacet")
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize ERC721Facet
        (bool success,) = address(diamond).call(
            abi.encodeWithSignature("initialize(string,string,uint256)", "DiamondNFT", "DNFT", 10000)
        );
        require(success, "ERC721Facet initialization failed");
    }

    function testERC721Functionality() public {
        // Test ERC721 functionality
        (bool success, bytes memory result) = address(diamond).call(abi.encodeWithSignature("name()"));
        require(success, "Name call failed");
        assertEq(abi.decode(result, (string)), "DiamondNFT", "Incorrect token name");

        (success, result) = address(diamond).call(abi.encodeWithSignature("symbol()"));
        require(success, "Symbol call failed");
        assertEq(abi.decode(result, (string)), "DNFT", "Incorrect token symbol");

        // Test minting
        (success,) = address(diamond).call(abi.encodeWithSignature("mint(address)", address(this)));
        require(success, "Minting failed");

        (success, result) = address(diamond).call(abi.encodeWithSignature("ownerOf(uint256)", 1));
        require(success, "OwnerOf call failed");
        assertEq(abi.decode(result, (address)), address(this), "Incorrect token owner");
    }

    function testPresaleFunctionality() public {
        // Test presale functionality
        (bool success,) = address(diamond).call(abi.encodeWithSignature("setPresaleActive(bool)", true));
        require(success, "Setting presale active failed");

        (success,) = address(diamond).call{value: 0.1 ether}(abi.encodeWithSignature("buyTokens()"));
        require(success, "Buying tokens failed");
    }

    function testMerkleFunctionality() public {
        // For this test, we'll need to generate a valid merkle root and proof
        // This is a simplified example and won't actually verify a real merkle proof
        bytes32 mockRoot = keccak256(abi.encodePacked("mock root"));
        (bool success,) = address(diamond).call(abi.encodeWithSignature("setMerkleRoot(bytes32)", mockRoot));
        require(success, "Setting merkle root failed");

        bytes32[] memory mockProof = new bytes32[](1);
        mockProof[0] = keccak256(abi.encodePacked("mock proof"));

        (success,) = address(diamond).call(abi.encodeWithSignature("claim(bytes32[],uint256)", mockProof, 1));
        // This will fail because we're not providing a valid proof
        assertTrue(!success, "Claim should fail with invalid proof");
    }

    function testDiamondLoupeFunctionality() public {
        // Test facets() function
        (bool success, bytes memory result) = address(diamond).call(abi.encodeWithSignature("facets()"));
        require(success, "Facets call failed");
        IDiamondLoupe.Facet[] memory facets = abi.decode(result, (IDiamondLoupe.Facet[]));
        assertEq(facets.length, 6, "Incorrect number of facets"); // Including DiamondCutFacet

        // Test facetFunctionSelectors() function
        (success, result) = address(diamond).call(abi.encodeWithSignature("facetFunctionSelectors(address)", address(erc721Facet)));
        require(success, "FacetFunctionSelectors call failed");
        bytes4[] memory selectors = abi.decode(result, (bytes4[]));
        assertTrue(selectors.length > 0, "No selectors found for ERC721Facet");

        // Test facetAddresses() function
        (success, result) = address(diamond).call(abi.encodeWithSignature("facetAddresses()"));
        require(success, "FacetAddresses call failed");
        address[] memory addresses = abi.decode(result, (address[]));
        assertEq(addresses.length, 6, "Incorrect number of facet addresses"); // Including DiamondCutFacet

        // Test facetAddress() function
        bytes4 mintSelector = bytes4(keccak256("mint(address)"));
        (success, result) = address(diamond).call(abi.encodeWithSignature("facetAddress(bytes4)", mintSelector));
        require(success, "FacetAddress call failed");
        address facetAddress = abi.decode(result, (address));
        assertEq(facetAddress, address(erc721Facet), "Incorrect facet address for mint function");
    }

    function testOwnershipFunctionality() public {
        // Test owner() function
        (bool success, bytes memory result) = address(diamond).call(abi.encodeWithSignature("owner()"));
        require(success, "Owner call failed");
        address owner = abi.decode(result, (address));
        assertEq(owner, address(this), "Incorrect owner");

        // Test transferOwnership() function
        address newOwner = address(0x123);
        (success,) = address(diamond).call(abi.encodeWithSignature("transferOwnership(address)", newOwner));
        require(success, "TransferOwnership call failed");

        // Verify the new owner
        (success, result) = address(diamond).call(abi.encodeWithSignature("owner()"));
        require(success, "Owner call failed");
        owner = abi.decode(result, (address));
        assertEq(owner, newOwner, "Ownership transfer failed");
    }

    receive() external payable {}
}