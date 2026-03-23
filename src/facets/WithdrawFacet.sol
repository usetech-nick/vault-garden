// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibVaultStorage} from "../libraries/LibVaultStorage.sol";

contract WithdrawFacet {
    error WithdrawFacet__InsufficientBalance();
    error WithdrawFacet__InsufficientContractBalance();
    error WithdrawFacet__InvalidAmount();
    error WithdrawFacet__TransferFailed();

    event Withdraw(address indexed user, uint256 amount);

    function withdraw(uint256 amount) external {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.getStorage();

        if (amount == 0) revert WithdrawFacet__InvalidAmount();
        if (vs.balances[msg.sender] < amount) revert WithdrawFacet__InsufficientBalance();
        if (address(this).balance < amount) revert WithdrawFacet__InsufficientContractBalance();

        vs.balances[msg.sender] -= amount;
        vs.totalDeposits -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert WithdrawFacet__TransferFailed();

        emit Withdraw(msg.sender, amount);
    }
}
