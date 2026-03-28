// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// interfaces/IProtocolRegistry.sol
interface IProtocolRegistry {
    function isWhitelisted(address facet) external view returns (bool);
}
