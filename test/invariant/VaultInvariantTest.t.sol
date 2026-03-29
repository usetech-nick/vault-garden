// test/invariant/VaultInvariantTest.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../../src/diamond/Diamond.sol";
import {DiamondFactory} from "../../src/diamond/DiamondFactory.sol";
import {DepositFacet} from "../../src/facets/DepositFacet.sol";
import {WithdrawFacet} from "../../src/facets/WithdrawFacet.sol";
import {BalanceFacet} from "../../src/facets/BalanceFacet.sol";
import {ProtocolRegistry} from "../../src/protocol/ProtocolRegistry.sol";
import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {VaultHandler} from "./handlers/VaultHandler.sol";

contract VaultInvariantTest is Test {
    Diamond diamond;
    VaultHandler handler;
    ProtocolRegistry registry;

    function setUp() public {
        // deploy protocol
        DepositFacet depositFacet = new DepositFacet();
        WithdrawFacet withdrawFacet = new WithdrawFacet();
        BalanceFacet balanceFacet = new BalanceFacet();
        registry = new ProtocolRegistry();

        // build cuts
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

        DiamondFactory factory = new DiamondFactory();
        address diamondAddr = factory.deployDiamond(address(this), cuts, address(registry));
        diamond = Diamond(payable(diamondAddr));

        // deploy handler and tell Foundry to only call handler functions
        handler = new VaultHandler(diamond);
        targetContract(address(handler));
    }

    function invariant_BalanceEqualsDeposits() public view {
        assertEq(address(diamond).balance, BalanceFacet(address(diamond)).getTotalDeposits());
    }
}
