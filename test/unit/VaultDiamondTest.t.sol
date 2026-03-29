// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "src/diamond/Diamond.sol";
import {DiamondFactory} from "src/diamond/DiamondFactory.sol";
import {ProtocolRegistry} from "src/protocol/ProtocolRegistry.sol";
import {DepositFacet} from "src/facets/DepositFacet.sol";
import {WithdrawFacet} from "src/facets/WithdrawFacet.sol";
import {BalanceFacet} from "src/facets/BalanceFacet.sol";
import {IDiamondCut as DC} from "src/interfaces/IDiamondCut.sol";

contract VaultDiamondTest is Test {
    Diamond diamond;
    DiamondFactory factory;
    ProtocolRegistry registry;
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
        registry = new ProtocolRegistry();

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
        address diamondAdd = factory.deployDiamond(owner, cuts, address(registry));
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
        new Diamond(owner, cuts, address(registry));
    }

    /////////////////////////////////////
    ///// AddFacet Tests ////////////////
    /////////////////////////////////////
    function test_OwnerCanAddFacetAndEmitEvent() public {
        address sampleAddr = address(1);
        bytes4 selector = bytes4(keccak256("sampleFunction(uint256)"));

        registry.whitelist(sampleAddr);

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

    ////////////////////////////////////////
    ///// removeFacet Tests ////////////////
    ////////////////////////////////////////

    function test_OwnerCanRemoveFacetAndEmitEvent() public {
        bytes4 selector = DepositFacet.deposit.selector;

        vm.expectEmit(true, true, false, false);
        emit Diamond.FacetRemoved(selector);

        vm.prank(owner);
        diamond.removeFacet(selector);

        assertEq(diamond.facetAddress(selector), address(0));
    }

    function test_NonOwnerCannotRemoveFacet() public {
        bytes4 selector = DepositFacet.deposit.selector;

        vm.prank(attacker);
        vm.expectRevert(Diamond.Diamond__NotOwner.selector);
        diamond.removeFacet(selector);
    }

    function test_RemovedSelectorReverts() public {
        bytes4 selector = DepositFacet.deposit.selector;

        vm.prank(owner);
        diamond.removeFacet(selector);

        vm.expectRevert(Diamond.Diamond__FacetNotFound.selector);
        (bool success,) = address(diamond).call(abi.encodeWithSelector(selector));
        assert(success);
    }

    ////////////////////////////////////////
    ///// Fallback Tests ///////////////////
    ////////////////////////////////////////

    function test_fallbackRoutesDepositCorrectly() public {
        uint256 depositAmount = 1 ether;
        vm.deal(user, depositAmount);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount);
    }

    function test_fallbackPassesThroughRevert() public {
        vm.prank(user);
        vm.expectRevert(WithdrawFacet.WithdrawFacet__InsufficientBalance.selector);
        WithdrawFacet(address(diamond)).withdraw(1 ether);
    }

    //////////////////////////////////////////
    /////////// Integration Tests ////////////
    //////////////////////////////////////////

    function test_DepositThenWithdraw() public {
        uint256 depositAmount = 1 ether;
        vm.deal(user, depositAmount);

        // Deposit
        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount);

        // Withdraw
        vm.prank(user);
        WithdrawFacet(address(diamond)).withdraw(depositAmount);

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), 0);
    }

    function test_MultipleUsersBalancesIsolated() public {
        uint256 depositAmount1 = 1 ether;
        uint256 depositAmount2 = 2 ether;
        address user2 = makeAddr("user2");

        vm.deal(user, depositAmount1);
        vm.deal(user2, depositAmount2);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount1}();

        vm.prank(user2);
        DepositFacet(address(diamond)).deposit{value: depositAmount2}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount1);
        assertEq(BalanceFacet(address(diamond)).getUserBalance(user2), depositAmount2);
    }

    //////////////////////////////////////////
    /////////// Fuzz Tests ////////////
    //////////////////////////////////////////

    function testfuzz_DepositAlwaysUpdatesBalance(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1, 1_000_000 ether);
        vm.deal(user, depositAmount);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount);
    }

    function testfuzz_MultipleDepositsAccumulate(uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, 1, 1_000_000 ether);
        depositAmount2 = bound(depositAmount2, 1, 1_000_000 ether);
        vm.deal(user, depositAmount1 + depositAmount2);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount1}();

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount2}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount1 + depositAmount2);
    }

    function testfuzz_CannotWithdrawMoreThanBalance(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, 1_000_000 ether);
        vm.deal(user, depositAmount);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount}();

        // bound AFTER deposit so we know the actual balance
        withdrawAmount = bound(withdrawAmount, depositAmount + 1, type(uint256).max);

        vm.prank(user);
        vm.expectRevert(WithdrawFacet.WithdrawFacet__InsufficientBalance.selector);
        WithdrawFacet(address(diamond)).withdraw(withdrawAmount);
    }

    function testfuzz_MultipleUsersBalancesIsolated(address user2, uint256 depositAmount1, uint256 depositAmount2)
        public
    {
        user2 = vm.addr((uint160(user2) % 1000 + 1)); // Limit to 1000 unique addresses
        depositAmount1 = bound(depositAmount1, 1, 1_000_000 ether);
        depositAmount2 = bound(depositAmount2, 1, 1_000_000 ether);
        vm.deal(user, depositAmount1);
        vm.deal(user2, depositAmount2);

        vm.prank(user);
        DepositFacet(address(diamond)).deposit{value: depositAmount1}();

        vm.prank(user2);
        DepositFacet(address(diamond)).deposit{value: depositAmount2}();

        assertEq(BalanceFacet(address(diamond)).getUserBalance(user), depositAmount1);
        assertEq(BalanceFacet(address(diamond)).getUserBalance(user2), depositAmount2);
    }
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
