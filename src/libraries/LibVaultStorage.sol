// LibVaultStorage.sol
library LibVaultStorage {
    bytes32 constant STORAGE_SLOT = keccak256("vault.garden.storage");

    struct VaultStorage {
        mapping(address => uint256) balances;
        uint256 totalDeposits;
        address owner;
    }

    function getStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            vs.slot := slot
        }
    }
}
