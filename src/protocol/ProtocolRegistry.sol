// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProtocolRegistry} from "../interfaces/IProtocolRegistry.sol";

contract ProtocolRegistry is IProtocolRegistry {
    error ProtocolRegistry__NotOwner();
    error ProtocolRegistry__NotWhitelistedProtocol();
    error ProtocolRegistry__AlreadyWhitelisted();
    error ProtocolRegistry__ZeroAddress();

    event ProtocolWhitelisted(address indexed facet);
    event ProtocolRemoved(address indexed facet);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    mapping(address => bool) public whitelisted;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) {
            revert ProtocolRegistry__NotOwner();
        }
        if (newOwner == address(0)) {
            revert ProtocolRegistry__ZeroAddress();
        }
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function whitelist(address facet) external {
        if (msg.sender != owner) {
            revert ProtocolRegistry__NotOwner();
        }
        if (whitelisted[facet]) {
            revert ProtocolRegistry__AlreadyWhitelisted();
        }
        if (facet == address(0)) revert ProtocolRegistry__ZeroAddress();

        whitelisted[facet] = true;
        emit ProtocolWhitelisted(facet);
    }

    function removeFacet(address facet) external {
        if (msg.sender != owner) {
            revert ProtocolRegistry__NotOwner();
        }
        if (!whitelisted[facet]) {
            revert ProtocolRegistry__NotWhitelistedProtocol();
        }
        if (facet == address(0)) revert ProtocolRegistry__ZeroAddress();

        whitelisted[facet] = false;
        emit ProtocolRemoved(facet);
    }

    function isWhitelisted(address facet) external view returns (bool) {
        return whitelisted[facet];
    }
}
