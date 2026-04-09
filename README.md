# Vault Garden

A Foundry-based smart contract project implementing a minimal vault protocol using a **Diamond-style proxy** architecture.

## Current MVP Status (from commits)

- Diamond proxy + factory implemented
- Protocol registry (facet whitelist) implemented
- Vault facets implemented:
  - `DepositFacet`
  - `WithdrawFacet`
  - `BalanceFacet`
- Deployment script completed and verified on Anvil
- Unit, fuzz, and invariant tests implemented

## Architecture Overview

- `src/diamond/Diamond.sol`  
  Selector routing via `fallback` + owner-controlled upgrades.

- `src/diamond/DiamondFactory.sol`  
  Deploys per-user vault diamonds.

- `src/protocol/ProtocolRegistry.sol`  
  Whitelist gate for facet addresses used in upgrades.

- `src/facets/*.sol`  
  Business logic split into modular facets.

- `src/libraries/LibDiamondStorage.sol` and `src/libraries/LibVaultStorage.sol`  
  Shared storage layouts used across delegatecalls.

## Test Coverage

Test suites currently include:

- Unit + integration-style tests for deployment, routing, ownership, add/remove facet, and core flows
- Fuzz tests for balance correctness and isolation
- Invariant test asserting:
  - `address(diamond).balance == getTotalDeposits()`

Latest run:

- **19/19 tests passing**
- Invariant campaign: **128,000 calls** with invariant holding

## Quick Start

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Install

```bash
forge install
```

### Build

```bash
forge build
```

### Run tests

```bash
forge test
```

### Local deploy (Anvil)

Start Anvil in one terminal:

```bash
anvil
```

Then deploy in another terminal:

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast
```

## Repository Layout

```text
src/
  aa/
  diamond/
  facets/
  interfaces/
  libraries/
  protocol/
script/
  Deploy.s.sol
test/
  unit/
  invariant/
```
