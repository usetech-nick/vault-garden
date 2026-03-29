// test/invariant/handlers/VaultHandler.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../../../src/diamond/Diamond.sol";
import {DepositFacet} from "../../../src/facets/DepositFacet.sol";
import {WithdrawFacet} from "../../../src/facets/WithdrawFacet.sol";
import {BalanceFacet} from "../../../src/facets/BalanceFacet.sol";

contract VaultHandler is Test {
    Diamond diamond;
    address[] public actors;
    address currentActor;

    constructor(Diamond _diamond) {
        diamond = _diamond;

        // create a set of actors to simulate multiple users
        actors.push(makeAddr("actor1"));
        actors.push(makeAddr("actor2"));
        actors.push(makeAddr("actor3"));

        // give each actor funds
        for (uint256 i = 0; i < actors.length; i++) {
            vm.deal(actors[i], 1000 ether);
        }
    }

    function deposit(uint256 actorSeed, uint256 amount) public {
        currentActor = actors[actorSeed % actors.length];
        amount = bound(amount, 1, 100 ether);

        vm.prank(currentActor);
        DepositFacet(address(diamond)).deposit{value: amount}();
    }

    function withdraw(uint256 actorSeed, uint256 amount) public {
        currentActor = actors[actorSeed % actors.length];

        uint256 balance = BalanceFacet(address(diamond)).getUserBalance(currentActor);

        if (balance == 0) return; // nothing to withdraw, skip

        amount = bound(amount, 1, balance);

        vm.prank(currentActor);
        WithdrawFacet(address(diamond)).withdraw(amount);
    }
}
