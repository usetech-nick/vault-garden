//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Diamond} from "./Diamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

contract DiamondFactory is IDiamondCut {
    error DiamondFactory__ZeroAddress();

    event DiamondDeployed(address indexed owner, address indexed diamond);

    function deployDiamond(address owner, FacetCut[] memory facetCuts) external returns (address) {
        if (owner == address(0)) revert DiamondFactory__ZeroAddress();

        Diamond diamond = new Diamond(owner, facetCuts);

        emit DiamondDeployed(owner, address(diamond));
        return address(diamond);
    }
}
