# Comet Contracts Architecture

This document explains the core architecture of the Comet protocol contracts, focusing on the extension pattern and the differences between regular and extended asset list variants.

## Table of Contents

- [Overview](#overview)
- [CometExt Extension Pattern](#cometext-extension-pattern)
- [Regular vs Extended Asset List](#regular-vs-extended-asset-list)
- [Minimum Deployment Requirements](#minimum-deployment-requirements)
- [Contract Relationships](#contract-relationships)

## Overview

The Comet protocol uses a modular architecture with two main components:

1. **Comet** (Main Contract) - Contains core protocol logic (supply, borrow, liquidate, etc.)
2. **CometExt** (Extension Contract) - Contains additional functions (ERC20 metadata, approvals, view helpers)

These contracts work together using a **delegatecall extension pattern** to stay within Ethereum contract size limits while maintaining upgradeability.

## CometExt Extension Pattern

### What "Ext" Stands For

"Ext" stands for **"Extension"** (not "external"). The directory name `ext-ernal-ensions` is a playful pun combining "external" and "extensions".

### How It Works

`CometExt` is **not** a periphery contract. Instead, it uses a **delegatecall extension pattern**:

1. `Comet` stores the address of `CometExt` in an immutable `extensionDelegate` variable
2. When a function call is made to `Comet` that doesn't match any function in `Comet`, the `fallback()` function is triggered
3. The `fallback()` function performs a `delegatecall` to `CometExt`, executing the extension's code in `Comet`'s storage context
4. This allows `CometExt` to access and modify `Comet`'s storage as if it were part of the same contract

### Key Contracts

#### `CometExtInterface.sol`

- Abstract interface defining functions implemented by `CometExt`
- Inherits from `CometCore` (shared storage/constants)
- Defines: `allow()`, `approve()`, `name()`, `symbol()`, view helpers, etc.

#### `CometExt.sol`

- Implementation of `CometExtInterface`
- Provides:
  - ERC20 metadata (`name()`, `symbol()`)
  - Approval system (`approve()`, `allowance()`, `allow()`, `allowBySig()`)
  - View helpers (`collateralBalanceOf()`, `baseTrackingAccrued()`, `totalsBasic()`)
  - Constant getters (`baseAccrualScale()`, `priceScale()`, etc.)
- Returns `maxAssets() = 15` (from `CometCore`)

### Why This Pattern?

1. **Contract Size Limits** - Splits functionality to stay under Ethereum's 24KB limit
2. **Upgradeability** - `CometExt` can be upgraded independently via `extensionDelegate`
3. **Separation of Concerns** - Core logic vs. ERC20/utility functions
4. **Storage Sharing** - Delegatecall allows `CometExt` to access `Comet`'s storage

## Regular vs Extended Asset List

### Regular Comet (`Comet.sol`)

**Asset Storage:**

- Stores assets directly in immutable storage variables
- Hardcoded slots: `asset00_a`, `asset00_b` through `asset11_a`, `asset11_b`
- Maximum: **12 assets** (indices 0-11)
- `getAssetInfo()` reads from own storage

**Extension:**

- Uses `CometExt.sol`
- `maxAssets()` returns 15 (from `CometCore.MAX_ASSETS`)

### Extended Asset List (`CometWithExtendedAssetList.sol`)

**Asset Storage:**

- Uses external `AssetList` contract for asset storage
- Creates `AssetList` during construction via `AssetListFactory`
- Maximum: **24 assets** (indices 0-23)
- `getAssetInfo()` delegates to `IAssetList(assetList).getAssetInfo(i)`

**Extension:**

- Uses `CometExtAssetList.sol` (extends `CometExt`)
- Stores `assetListFactory` address
- `maxAssets()` returns 24

### Key Differences

| Feature            | Regular Comet           | Extended Asset List                     |
| ------------------ | ----------------------- | --------------------------------------- |
| Main Contract      | `Comet.sol`             | `CometWithExtendedAssetList.sol`        |
| Extension          | `CometExt.sol`          | `CometExtAssetList.sol`                 |
| Factory            | `CometFactory.sol`      | `CometFactoryWithExtendedAssetList.sol` |
| Asset Storage      | Direct (immutable vars) | External `AssetList` contract           |
| Max Assets         | 12 (hardcoded)          | 24 (via `AssetList`)                    |
| Asset List Factory | Not needed              | Required                                |

### AssetList Contract

`AssetList.sol` is **only used for the extended variant**, not for regular `Comet`:

- Separate contract that stores up to 24 assets in packed immutable storage
- Created by `AssetListFactory` during `CometWithExtendedAssetList` construction
- Provides `getAssetInfo(uint8 i)` for asset lookups
- Used to avoid exceeding contract size limits when supporting more assets

## Minimum Deployment Requirements

### Simplest Version (Regular Comet)

For the simplest deployment of Comet (without extended asset list), you need:

#### Core Contracts

1. **`Comet.sol`** - Main protocol implementation

   - Stores up to 12 assets directly
   - Contains all core protocol logic

2. **`CometExt.sol`** - Extension contract

   - Provides ERC20 functions, approvals, view helpers
   - Deployed separately, address passed to `Comet` as `extensionDelegate`

3. **`CometFactory.sol`** - Factory for deploying new Comet instances

   - Used by Configurator during upgrades

4. **`CometProxyAdmin.sol`** - Proxy admin for upgradeable proxy

   - Manages proxy upgrades

5. **`TransparentUpgradeableProxy.sol`** - Upgradeable proxy
   - Wraps `Comet` implementation for upgradeability

#### Optional but Recommended

6. **`Configurator.sol`** - Governance contract for managing Comet

   - Allows upgrading implementations and changing configuration

7. **`ConfiguratorProxy.sol`** - Proxy for Configurator

   - Makes Configurator upgradeable

8. **`CometRewards.sol`** - Rewards distribution contract
   - Distributes COMP tokens to suppliers and borrowers

#### Dependencies

- **`CometCore.sol`** - Shared base contract (inherited, not deployed)
- **`CometMainInterface.sol`** - Interface definitions (inherited, not deployed)
- **`CometExtInterface.sol`** - Extension interface (inherited, not deployed)
- **`CometStorage.sol`** - Storage layout (inherited, not deployed)
- **`CometConfiguration.sol`** - Configuration structs (inherited, not deployed)
- **`CometMath.sol`** - Math utilities (inherited, not deployed)

### Compulsory Contracts for Extended Asset Support

For deployments requiring more than 12 assets (up to 24), you need all of the above **plus**:

#### Additional Contracts

1. **`CometWithExtendedAssetList.sol`** - Main protocol with extended asset support

   - Replaces `Comet.sol`
   - Uses external `AssetList` for asset storage

2. **`CometExtAssetList.sol`** - Extension for extended asset list

   - Replaces `CometExt.sol`
   - Stores `assetListFactory` address
   - Returns `maxAssets() = 24`

3. **`CometFactoryWithExtendedAssetList.sol`** - Factory for extended variant

   - Replaces `CometFactory.sol`

4. **`AssetListFactory.sol`** - Factory for creating `AssetList` contracts

   - Creates `AssetList` instances during `CometWithExtendedAssetList` construction

5. **`AssetList.sol`** - Asset storage contract
   - Created per deployment by `AssetListFactory`
   - Stores up to 24 assets in packed immutable storage

#### Interface Dependencies

- **`IAssetList.sol`** - Interface for `AssetList` contract
- **`IAssetListFactory.sol`** - Interface for `AssetListFactory`
- **`IAssetListFactoryHolder.sol`** - Interface for contracts holding asset list factory address

### Deployment Flow Comparison

#### Regular Comet Deployment

```
1. Deploy CometExt
   └── Stores name32, symbol32

2. Deploy CometFactory

3. Deploy Comet (via factory or directly)
   └── Takes extensionDelegate = CometExt.address
   └── Stores assets directly (up to 12)

4. Deploy CometProxyAdmin

5. Deploy TransparentUpgradeableProxy
   └── Points to Comet implementation
   └── Admin = CometProxyAdmin
```

#### Extended Asset List Deployment

```
1. Deploy AssetListFactory

2. Deploy CometExtAssetList
   └── Takes ExtConfiguration + AssetListFactory.address
   └── Stores assetListFactory

3. Deploy CometFactoryWithExtendedAssetList

4. Deploy CometWithExtendedAssetList
   └── Takes extensionDelegate = CometExtAssetList.address
   └── Creates AssetList via AssetListFactory
   └── Stores assetList address

5. Deploy CometProxyAdmin

6. Deploy TransparentUpgradeableProxy
   └── Points to CometWithExtendedAssetList implementation
   └── Admin = CometProxyAdmin
```

## Contract Relationships

### Inheritance Hierarchy

```
CometCore
├── CometStorage
├── CometConfiguration
└── CometMath

CometMainInterface
└── CometCore

CometExtInterface
└── CometCore

Comet
└── CometMainInterface

CometExt
└── CometExtInterface

CometExtAssetList
└── CometExt
    └── CometExtInterface

CometWithExtendedAssetList
└── CometMainInterface
```

### Delegatecall Flow

```
User calls Comet.functionName()
    │
    ├─ Function exists in Comet?
    │   └─ Yes → Execute in Comet
    │   └─ No → Fallback triggered
    │       └─ delegatecall(extensionDelegate, ...)
    │           └─ Execute in CometExt (using Comet's storage)
```

### Asset Storage Comparison

**Regular Comet:**

```
Comet.sol
├── asset00_a, asset00_b (immutable)
├── asset01_a, asset01_b (immutable)
├── ...
└── asset11_a, asset11_b (immutable)
```

**Extended Asset List:**

```
CometWithExtendedAssetList.sol
└── assetList (address, immutable)
    └── AssetList.sol
        ├── asset00_a, asset00_b (immutable)
        ├── asset01_a, asset01_b (immutable)
        ├── ...
        └── asset23_a, asset23_b (immutable)
```

## Summary

- **CometExt** = Extension contract pattern using delegatecall (not a periphery contract)
- **Regular Comet** = Stores up to 12 assets directly, uses `CometExt`
- **Extended Asset List** = Stores up to 24 assets via external `AssetList`, uses `CometExtAssetList`
- **AssetList** = Only used for extended variant, not for regular Comet
- **Minimum deployment** = `Comet` + `CometExt` + `CometFactory` + Proxy infrastructure
- **Extended deployment** = All of the above + `CometWithExtendedAssetList` + `CometExtAssetList` + `AssetListFactory` + `AssetList`
