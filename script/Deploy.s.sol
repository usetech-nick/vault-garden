// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ProtocolRegistry} from "../src/protocol/ProtocolRegistry.sol";
import {DiamondFactory} from "../src/diamond/DiamondFactory.sol";
import {Diamond} from "../src/diamond/Diamond.sol";
import {DepositFacet} from "../src/facets/DepositFacet.sol";
import {WithdrawFacet} from "../src/facets/WithdrawFacet.sol";
import {BalanceFacet} from "../src/facets/BalanceFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

contract Deploy is Script {
    function run() external returns (address registry, address factory, address diamond) {
        vm.startBroadcast();

        // 1. deploy registry
        ProtocolRegistry protocolRegistry = new ProtocolRegistry();
        console.log("ProtocolRegistry:", address(protocolRegistry));

        // 2. deploy facet implementations
        DepositFacet depositFacet = new DepositFacet();
        WithdrawFacet withdrawFacet = new WithdrawFacet();
        BalanceFacet balanceFacet = new BalanceFacet();
        console.log("DepositFacet:", address(depositFacet));
        console.log("WithdrawFacet:", address(withdrawFacet));
        console.log("BalanceFacet:", address(balanceFacet));

        // 3. build cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        bytes4[] memory depositSelectors = new bytes4[](1);
        depositSelectors[0] = DepositFacet.deposit.selector;
        cuts[0] = IDiamondCut.FacetCut({facetAddress: address(depositFacet), selectors: depositSelectors});

        bytes4[] memory withdrawSelectors = new bytes4[](1);
        withdrawSelectors[0] = WithdrawFacet.withdraw.selector;
        cuts[1] = IDiamondCut.FacetCut({facetAddress: address(withdrawFacet), selectors: withdrawSelectors});

        bytes4[] memory balanceSelectors = new bytes4[](2);
        balanceSelectors[0] = BalanceFacet.getUserBalance.selector;
        balanceSelectors[1] = BalanceFacet.getTotalDeposits.selector;
        cuts[2] = IDiamondCut.FacetCut({facetAddress: address(balanceFacet), selectors: balanceSelectors});

        // 4. deploy factory
        DiamondFactory diamondFactory = new DiamondFactory();
        console.log("DiamondFactory:", address(diamondFactory));

        // 5. deploy one user vault
        address owner = msg.sender;
        address diamondAddr = diamondFactory.deployDiamond(owner, cuts, address(protocolRegistry));
        console.log("Diamond (user vault):", diamondAddr);
        console.log("Vault owner:", owner);

        vm.stopBroadcast();

        return (address(protocolRegistry), address(diamondFactory), diamondAddr);
    }
}
