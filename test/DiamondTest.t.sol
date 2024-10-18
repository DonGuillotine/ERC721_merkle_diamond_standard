// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./JSONReader.sol";
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

contract DiamondTest is Test, DiamondUtils, IERC721Receiver, JSONReader {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC721Facet erc721Facet;
    MerkleFacet merkleFacet;
    PresaleFacet presaleFacet;

    bytes32 merkleRoot;
    bytes32[][] merkleProofs;
    address[] whitelistAddresses;
    uint256[] whitelistAmounts;


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

        string memory jsonData = readJSONFile("merkleData.json");
        console.log("JSON data:", jsonData);

        bytes memory rootData = vm.parseJson(jsonData, ".root");
        require(rootData.length > 0, "Failed to parse root");
        merkleRoot = abi.decode(rootData, (bytes32));

        bytes memory addressesData = vm.parseJson(jsonData, ".addresses");
        require(addressesData.length > 0, "Failed to parse addresses");
        whitelistAddresses = abi.decode(addressesData, (address[]));

        bytes memory amountsData = vm.parseJson(jsonData, ".amounts");
        require(amountsData.length > 0, "Failed to parse amounts");
        whitelistAmounts = abi.decode(amountsData, (uint256[]));

        bytes memory proofsData = vm.parseJson(jsonData, ".proofs");
        require(proofsData.length > 0, "Failed to parse proofs");
        merkleProofs = abi.decode(proofsData, (bytes32[][]));

        require(whitelistAddresses.length == whitelistAmounts.length, "Mismatch in addresses and amounts");
        require(whitelistAddresses.length == merkleProofs.length, "Mismatch in addresses and proofs");

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
        // Set the merkle root
        (bool success,) = address(diamond).call(abi.encodeWithSignature("setMerkleRoot(bytes32)", merkleRoot));
        require(success, "Setting merkle root failed");

        // Test claiming for each address in the whitelist
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            address claimer = whitelistAddresses[i];
            uint256 amount = whitelistAmounts[i];
            bytes32[] memory proof = merkleProofs[i];

            vm.prank(claimer);
            (success,) = address(diamond).call(abi.encodeWithSignature("claim(bytes32[],uint256)", proof, amount));
            require(success, "Claim failed");

            // Try to claim again (should fail)
            vm.prank(claimer);
            (success,) = address(diamond).call(abi.encodeWithSignature("claim(bytes32[],uint256)", proof, amount));
            require(!success, "Double claim should fail");
        }

        // Try to claim with an invalid proof
        address invalidClaimer = address(0x9999);
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(0);
        vm.prank(invalidClaimer);
        (success,) = address(diamond).call(abi.encodeWithSignature("claim(bytes32[],uint256)", invalidProof, 1000));
        require(!success, "Claim with invalid proof should fail");
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