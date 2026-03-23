// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibVaultStorage} from "../libraries/LibVaultStorage.sol";

contract BalanceFacet {
    function getUserBalance(address user) external view returns (uint256) {
        return LibVaultStorage.getStorage().balances[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.getStorage();
        return vs.totalDeposits;
    }
}
