# NebulaYield Eviction Vault

A secure, multi-owner Solidity smart contract system for managing vault deposits, multi-signature transactions, and Merkle proof-based claims.

## Overview

The EvictionVault system consists of three main modular contracts:

- **VaultManager**: Handles core vault deposits, withdrawals, and owner management
- **TransactionManager**: Manages multi-signature transaction submissions, confirmations, and execution with timelock
- **ClaimManager**: Processes Merkle proof-based claims and signature verification
- **EvictionVault**: Main contract combining all three managers with proper diamond inheritance resolution

## Key Changes from Original (EvictionVault1.sol to EvictionVaultCorrections.sol)

### 1. **Custom Error Types**

- **Before**: Used string error messages (`require(..., "error message")`)
- **After**: Implemented custom error types for gas efficiency:
  ```solidity
  error NotOwner();
  error NoOwners();
  error AddressZero();
  error Paused();
  error Claimed();
  error InsufficientBalance();
  error Executed();
  error Confirmed();
  error NotEnoughConfirmation();
  error Failed();
  ```

### 2. **Access Control Improvements**

- **Before**: Inline owner checks in each function
- **After**: Created `onlyOwner` modifier for consistent access control
- Added owner verification to `setMerkleRoot()` function (was missing)

### 3. **Security Enhancements**

#### Ether Reception

- **Before**: `receive()` used `tx.origin` (unsafe)
- **After**: Uses `msg.sender` (proper practice)

#### Safe Withdrawal Pattern

- **Before**: Used `.transfer()` method (deprecated, throws on failure and reverts when the transaction gas exceeds what transfer stipulates)
- **After**: Uses low-level `.call{}` with success verification:
  ```solidity
  (bool success,) = payable(msg.sender).call{value: amount}("");
  require(success, Failed());
  ```

#### Constructor Validation

- **Before**: Missing validation for zero-address owners
- **After**: Added explicit `AddressZero()` error checking in constructor

### 4. **Return Values**

- **Before**: Functions like `withdraw()` and `claim()` had no return values
- **After**: Added `returns(bool)` with proper success indication

### 5. **Transaction Management Improvements**

- **Before**: Missing owner verification in `submitTransaction()`
- **After**: Added `onlyOwner` modifier to ensure only owners can submit
- Added check for sufficient balance before transaction submission
- Improved confirmations tracking with explicit error handling

### 6. **Signature Verification**

- **Before**: Used incorrect `MerkleProof.recover()` method
- **After**: Imported and uses proper `ECDSA.recover()` from OpenZeppelin

### 7. **Architecture Refactoring**

- **Before**: Monolithic contract with all logic in one file
- **After**: Modular design split into:
  - `VaultManager.sol` - Core vault functionality
  - `TransactionManager.sol` - Multi-sig logic
  - `ClaimManager.sol` - Merkle-based claims
  - `EvictionVault.sol` - Main contract combining all modules

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Foundry Documentation

https://book.getfoundry.sh/
