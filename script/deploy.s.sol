// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import { ERC721Facet } from "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/MerkleFacet.sol";
import "../contracts/facets/PresaleFacet.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "./helpers/DiamondUtils.sol";

contract DeployDiamond is Script, DiamondUtils {
    function run() external {
        // Anvil test account for local deployment
        // This is deployed to 0x5fbdb2315678afecb367f032d93f642f64180aa3
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        vm.startBroadcast(deployer);

        // Deploy DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        Diamond diamond = new Diamond(deployer, address(diamondCutFacet));

        // Deploy facets
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ERC721Facet erc721Facet = new ERC721Facet();
        MerkleFacet merkleFacet = new MerkleFacet();
        PresaleFacet presaleFacet = new PresaleFacet();

        // Prepare cut struct for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors("DiamondLoupeFacet")
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors("OwnershipFacet")
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(erc721Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors("ERC721Facet")
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(merkleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors("MerkleFacet")
        });

        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(presaleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors("PresaleFacet")
        });

        // Add facets to Diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize ERC721Facet
        (bool success,) = address(diamond).call(
            abi.encodeWithSignature("initialize(string,string,uint256)", "DiamondNFT", "DNFT", 10000)
        );
        require(success, "ERC721Facet initialization failed");

        vm.stopBroadcast();
    }
}