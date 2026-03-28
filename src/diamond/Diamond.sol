// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibDiamondStorage} from "../libraries/LibDiamondStorage.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IProtocolRegistry} from "../interfaces/IProtocolRegistry.sol";

contract Diamond is IDiamondCut {
    error Diamond__NotOwner();
    error Diamond__FacetNotFound();
    error Diamond__ZeroAddress();
    error Diamond__SelectorExists();
    error Diamond__FacetNotWhitelisted();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FacetAdded(bytes4 indexed selector, address indexed facet);
    event FacetRemoved(bytes4 indexed selector);

    // Deployment time:
    //   Factory → new Diamond(owner, cuts) → constructor registers facets internally
    //                                         no msg.sender check needed
    constructor(address _owner, FacetCut[] memory facetCuts, address _registry) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.getStorage();

        ds.owner = _owner;
        ds.registry = _registry;

        for (uint256 i = 0; i < facetCuts.length; i++) {
            FacetCut memory facetCut = facetCuts[i];

            if (facetCut.facetAddress == address(0)) revert Diamond__ZeroAddress();

            for (uint256 j = 0; j < facetCut.selectors.length; j++) {
                bytes4 selector = facetCut.selectors[j];

                if (ds.selectorToFacet[selector] != address(0)) {
                    revert Diamond__SelectorExists();
                }

                ds.selectorToFacet[selector] = facetCut.facetAddress;
                emit FacetAdded(selector, facetCut.facetAddress);
            }
        }
    }

    // ── admin ──────────────────────────────────────────

    function transferOwnership(address newOwner) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.getStorage();
        if (msg.sender != ds.owner) revert Diamond__NotOwner();
        if (newOwner == address(0)) revert Diamond__ZeroAddress();
        emit OwnershipTransferred(ds.owner, newOwner);
        ds.owner = newOwner;
    }

    // Upgrade time:
    //   Owner → diamond.addFacet(selector, newFacet) → owner check passes
    function addFacet(bytes4 selector, address facet) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.getStorage();

        if (msg.sender != ds.owner) revert Diamond__NotOwner();
        if (facet == address(0)) revert Diamond__ZeroAddress();
        if (ds.selectorToFacet[selector] != address(0)) revert Diamond__SelectorExists();
        if (!IProtocolRegistry(ds.registry).isWhitelisted(facet)) revert Diamond__FacetNotWhitelisted();

        ds.selectorToFacet[selector] = facet;
        emit FacetAdded(selector, facet);
    }

    function removeFacet(bytes4 selector) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.getStorage();

        if (msg.sender != ds.owner) revert Diamond__NotOwner();

        delete ds.selectorToFacet[selector];
        emit FacetRemoved(selector);
    }

    // ── routing ────────────────────────────────────────

    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.getStorage();

        address facet = ds.selectorToFacet[msg.sig];
        if (facet == address(0)) revert Diamond__FacetNotFound();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // view function to get facet for a selector (used in tests)
    function facetAddress(bytes4 selector) external view returns (address) {
        return LibDiamondStorage.getStorage().selectorToFacet[selector];
    }

    // view function to get owner (used in tests)
    function owner() external view returns (address) {
        return LibDiamondStorage.getStorage().owner;
    }

    receive() external payable {}
}
