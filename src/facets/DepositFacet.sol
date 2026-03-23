// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibVaultStorage} from "../libraries/LibVaultStorage.sol";

contract DepositFacet {
    error DepositFacet__InvalidAmount();

    event Deposit(address indexed user, uint256 amount);

    function deposit() external payable {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.getStorage();

        if (msg.value == 0) revert DepositFacet__InvalidAmount();

        vs.balances[msg.sender] += msg.value;
        vs.totalDeposits += msg.value;

        emit Deposit(msg.sender, msg.value);
    }
}
