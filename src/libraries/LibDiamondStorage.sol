//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library LibDiamondStorage {
    bytes32 constant STORAGE_SLOT = keccak256("vault.garden.diamond");

    struct DiamondStorage {
        mapping(bytes4 => address) selectorToFacet;
        address owner;
        address registry;
    }

    function getStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }
}
