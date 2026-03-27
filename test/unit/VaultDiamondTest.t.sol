// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Diamond} from "src/diamond/Diamond.sol";
import {DiamondFactory} from "src/diamond/DiamondFactory.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {WithdrawFacet} from "src/facets/WithdrawFacet.sol";
import {BalanceFacet} from "src/facets/BalanceFacet.sol";
import {IDiamondCut as DC} from "src/interfaces/IDiamondCut.sol";

contract VaultDiamondTest is Test {
    Diamond diamond;
    DiamondFactory factory;
    DepositFacet depositFacet;
    WithdrawFacet withdrawFacet;
    BalanceFacet balanceFacet;
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        depositFacet = new DepositFacet();
        withdrawFacet = new WithdrawFacet();
        balanceFacet = new BalanceFacet();

        DC.FacetCut[] memory cuts = new DC.FacetCut[](3);

        bytes4[] memory depositSelectors = new bytes4[](1);
        depositSelectors[0] = depositFacet.deposit.selector;
        cuts[0] = DC.FacetCut({facetAddress: address(depositFacet), selectors: depositSelectors});

        bytes4[] memory withdrawSelectors = new bytes4[](1);
        withdrawSelectors[0] = withdrawFacet.withdraw.selector;
        cuts[1] = DC.FacetCut({facetAddress: address(withdrawFacet), selectors: withdrawSelectors});

        bytes4[] memory balanceSelectors = new bytes4[](2);
        balanceSelectors[0] = balanceFacet.getUserBalance.selector;
        balanceSelectors[1] = balanceFacet.getTotalDeposits.selector;
        cuts[2] = DC.FacetCut({facetAddress: address(balanceFacet), selectors: balanceSelectors});

        factory = new DiamondFactory();
        address diamondAdd = factory.deployDiamond(owner, cuts);
        diamond = Diamond(payable(diamondAdd));
    }

    /////////////////////////////////////
    ///// Constructor Tests /////////////
    /////////////////////////////////////
    function test_OwnerSetCorrectly() public view {
        assertEq(diamond.owner(), owner);
    }

    function test_DepositSelectorRegistered() public view {
        assertEq(diamond.facetAddress(DepositFacet.deposit.selector), address(depositFacet));
    }

    function test_WithdrawSelectorRegistered() public view {
        assertEq(diamond.facetAddress(WithdrawFacet.withdraw.selector), address(withdrawFacet));
    }

    function test_BalanceSelectorRegistered() public view {
        assertEq(diamond.facetAddress(BalanceFacet.getUserBalance.selector), address(balanceFacet));
    }

    function test_RevertOnDuplicateSelector() public {
        DC.FacetCut[] memory cuts = new DC.FacetCut[](2);

        bytes4[] memory selectors0 = new bytes4[](1);
        selectors0[0] = DepositFacet.deposit.selector;
        cuts[0] = DC.FacetCut({facetAddress: address(depositFacet), selectors: selectors0});

        bytes4[] memory selectors1 = new bytes4[](1);
        selectors1[0] = DepositFacet.deposit.selector;
        cuts[1] = DC.FacetCut({facetAddress: address(withdrawFacet), selectors: selectors1});

        vm.expectRevert(Diamond.Diamond__SelectorExists.selector);
        new Diamond(owner, cuts);
    }

    /////////////////////////////////////
    ///// AddFacet Tests ////////////////
    /////////////////////////////////////
    function test_OwnerCanAddFacetAndEmitEvent() public {
        address sampleAddr = address(1);
        bytes4 selector = bytes4(keccak256("sampleFunction(uint256)"));

        vm.expectEmit(true, true, false, false);
        emit Diamond.FacetAdded(selector, sampleAddr);

        vm.prank(owner);
        diamond.addFacet(selector, sampleAddr);

        assertEq(diamond.facetAddress(selector), sampleAddr);
    }

    function test_NonOwnerCannotAddFacet() public {
        address sampleAddr = address(1);
        bytes4 selector = bytes4(keccak256("sampleFunction(uint256)"));

        vm.prank(attacker);
        vm.expectRevert(Diamond.Diamond__NotOwner.selector);
        diamond.addFacet(selector, sampleAddr);
    }

    // Diamond contract
    // ├── Constructor
    // │   ├── owner set correctly
    // │   ├── all selectors registered correctly
    // │   ├── duplicate selector reverts with SelectorExists
    // │   ├── zero address facet reverts with ZeroAddress
    // │   └── events emitted for each selector
    // ├── addFacet
    // │   ├── owner can add new selector
    // │   ├── selector mapped to correct facet after add
    // │   ├── emits FacetAdded event
    // │   ├── non-owner reverts with NotOwner
    // │   └── zero address facet reverts with ZeroAddress
    // ├── removeFacet
    // │   ├── owner can remove selector
    // │   ├── selector maps to zero address after remove
    // │   ├── emits FacetRemoved event
    // │   └── non-owner reverts with NotOwner
    // ├── transferOwnership
    // │   ├── owner can transfer to new address
    // │   ├── new owner can call addFacet
    // │   ├── old owner cannot call addFacet after transfer
    // │   ├── zero address reverts
    // │   └── emits OwnershipTransferred event
    // ├── fallback routing
    // │   ├── known selector routes to correct facet
    // │   ├── unknown selector reverts with FacetNotFound
    // │   ├── return data passes through correctly
    // │   └── revert reason passes through correctly
    // └── receive
    //     └── accepts plain ETH transfers

    /////////// Facet Tests ////////////
    //     Unit
    // ├── DepositFacet
    // │   ├── deposit updates balance correctly
    // │   ├── deposit updates totalDeposits correctly
    // │   ├── deposit emits event
    // │   └── deposit reverts on zero value
    // ├── WithdrawFacet
    // │   ├── withdraw updates balance correctly
    // │   ├── withdraw sends ETH to user
    // │   ├── withdraw emits event
    // │   ├── withdraw reverts on zero amount
    // │   ├── withdraw reverts on insufficient balance
    // │   └── withdraw reverts on insufficient contract balance
    // └── BalanceFacet
    //     ├── getUserBalance returns correct balance
    //     └── getTotalDeposits returns correct total

    // Integration
    // ├── Diamond deployment
    // │   ├── factory deploys diamond with correct owner
    // │   ├── all selectors registered correctly
    // │   └── duplicate selector reverts
    // ├── Full deposit flow
    // │   └── user calls deposit() on diamond address → balance updated
    // ├── Full withdraw flow
    // │   └── user calls withdraw() on diamond address → ETH received
    // ├── Full balance flow
    // │   └── getUserBalance via diamond returns correct value
    // └── Upgrade flow
    //     ├── owner can addFacet post deployment
    //     ├── owner can removeFacet
    //     ├── non-owner cannot addFacet
    //     └── calling removed selector reverts

    // Fuzz
    // ├── fuzz deposit amount → balance always equals sum of deposits
    // ├── fuzz withdraw amount → never withdraw more than balance
    // └── fuzz multiple users → balances never interfere with each other
}
