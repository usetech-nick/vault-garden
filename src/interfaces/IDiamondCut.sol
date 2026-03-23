// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// interfaces/IDiamondCut.sol
interface IDiamondCut {
    struct FacetCut {
        address facetAddress;
        bytes4[] selectors;
    }
}
