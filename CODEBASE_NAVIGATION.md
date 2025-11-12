# Comet Protocol Codebase Navigation Guide

This guide helps you quickly navigate the Comet protocol codebase by mapping features to specific files. Use this as a reference when you need to understand or modify a particular feature.

## Quick Reference Table

| Feature | Primary Contracts | Tests | Scenarios |
|---------|------------------|-------|-----------|
| **Core Operations** | `Comet.sol`, `CometCore.sol` | `supply-test.ts`, `withdraw-test.ts`, `transfer-test.ts` | `SupplyScenario.ts`, `WithdrawScenario.ts`, `TransferScenario.ts` |
| **Liquidation** | `Comet.sol` (absorb), `OnChainLiquidator.sol` | `absorb-test.ts`, `buy-collateral-test.ts` | `LiquidationScenario.ts`, `LiquidationBotScenario.ts` |
| **Governance** | `Configurator.sol`, `ConfiguratorStorage.sol` | `configurator-test.ts` | `ConfiguratorScenario.ts`, `GovernanceScenario.ts` |
| **Rewards** | `CometRewards.sol` | `rewards-test.ts` | `RewardsScenario.ts` |
| **Bulker** | `BaseBulker.sol`, `MainnetBulker.sol` | `bulker-test.ts` | `BulkerScenario.ts`, `MainnetBulkerScenario.ts` |
| **Bridges** | `bridges/*/BridgeReceiver.sol` | `bridges/*-test.ts` | `CrossChainGovernanceScenario.ts` |
| **Price Feeds** | `pricefeeds/*.sol` | `pricefeeds/*-test.ts` | - |
| **Interest Rates** | `Comet.sol`, `CometMath.sol` | `interest-rate-test.ts` | `InterestRateScenario.ts` |
| **Asset Management** | `AssetList.sol`, `AssetListFactory.sol` | `asset-info-test.ts` | - |

---

## 1. Core Protocol Operations

### Overview
The core operations include supplying assets (base token or collateral), borrowing base tokens, withdrawing, and transferring positions. These are the fundamental user-facing functions of the protocol.

### Primary Contract Files

**`contracts/Comet.sol`**
- Main implementation contract for Comet protocol
- Contains `supply()`, `supplyTo()`, `supplyFrom()` for supplying assets
- Contains `withdraw()`, `withdrawTo()`, `withdrawFrom()` for withdrawing
- Contains `transfer()`, `transferFrom()` for base token transfers
- Contains `transferAsset()`, `transferAssetFrom()` for collateral transfers
- Handles both base token and collateral operations
- **Key functions:**
  - `supplyInternal()` - Core supply logic
  - `withdrawInternal()` - Core withdraw logic
  - `transferInternal()` - Core transfer logic
  - `supplyBase()` - Base token supply
  - `supplyCollateral()` - Collateral supply
  - `withdrawBase()` - Base token withdrawal
  - `withdrawCollateral()` - Collateral withdrawal

**`contracts/CometCore.sol`**
- Abstract contract containing shared logic between `Comet.sol` and `CometExt.sol`
- Defines `AssetInfo` struct and asset management utilities
- Contains permission checking (`hasPermission()`)
- Contains present value calculations for supply/borrow balances
- Defines constants (MAX_ASSETS, pause flags, scales, etc.)

**`contracts/CometStorage.sol`**
- Defines all storage structures:
  - `TotalsBasic` - Aggregate market state (indices, totals, pause flags)
  - `TotalsCollateral` - Per-asset collateral totals
  - `UserBasic` - User's base position (principal, tracking indices)
  - `UserCollateral` - User's collateral balances per asset
  - `LiquidatorPoints` - Liquidator tracking data
- Storage mappings for users, permissions, and collateral

**`contracts/CometMath.sol`**
- Pure math utility functions
- Safe type conversions (safe64, safe104, safe128, etc.)
- Signed/unsigned conversions

**`contracts/CometExt.sol`**
- Extension contract for ERC20 functions (`approve`, `allowance`)
- Called via delegatecall from Comet proxy

**`contracts/CometInterface.sol`**
- Combined interface for `CometMainInterface` and `CometExtInterface`
- Use this for type definitions when interacting with Comet

### Test Files

**`test/supply-test.ts`**
- Tests for supplying base tokens and collateral
- Tests supply permissions and edge cases

**`test/withdraw-test.ts`**
- Tests for withdrawing base tokens and collateral
- Tests withdrawal limits and collateralization checks

**`test/transfer-test.ts`**
- Tests for transferring base tokens and collateral
- Tests transfer permissions

**`test/balance-test.ts`**
- Tests for balance queries (supply, borrow, collateral)

**`test/is-borrow-collateralized-test.ts`**
- Tests for checking if a borrow position is properly collateralized

### Scenario Files

**`scenario/SupplyScenario.ts`**
- Property-based tests for supply operations
- Tests various supply scenarios and constraints

**`scenario/WithdrawScenario.ts`**
- Property-based tests for withdraw operations
- Tests withdrawal limits and safety checks

**`scenario/TransferScenario.ts`**
- Property-based tests for transfer operations
- Tests transfer permissions and edge cases

**`scenario/CometScenario.ts`**
- General Comet protocol scenarios combining multiple operations

### Related Utilities

**`test/helpers.ts`**
- `makeProtocol()` - Creates a test protocol instance
- Helper functions for setting up test environments

**`scenario/context/CometContext.ts`**
- Context management for scenario tests
- Provides actors, assets, and protocol instances

---

## 2. Liquidation System

### Overview
Comet uses an "absorb" mechanism where the protocol itself absorbs underwater positions, then sells the collateral. Liquidators can purchase the absorbed collateral at a discount.

### Primary Contract Files

**`contracts/Comet.sol`**
- `absorb()` - Public function to absorb underwater accounts
- `absorbInternal()` - Core liquidation logic
  - Seizes collateral from underwater accounts
  - Converts collateral to base tokens using liquidation factor
  - Updates user's principal (may go to zero if fully liquidated)
  - Resets user's `assetsIn` tracking
- `isLiquidatable()` - Checks if an account can be liquidated
- `buyCollateral()` - Allows purchasing absorbed collateral at a discount
- `quoteCollateral()` - Quotes the amount of base tokens needed to buy collateral

**`contracts/liquidator/OnChainLiquidator.sol`**
- Automated liquidation bot contract
- `absorbAndArbitrage()` - Absorbs accounts and purchases collateral in one transaction
- Uses Uniswap V3 flash loans to purchase collateral
- Handles multiple assets and accounts in a single transaction
- **Key features:**
  - Flash loan integration
  - Uniswap V3 pool interaction
  - Multi-asset support
  - Gas optimization for liquidators

**`contracts/liquidator/interfaces/`**
- `IUniswapV2Router.sol` - Uniswap V2 router interface
- `IStableSwap.sol` - Stable swap interface
- `IVault.sol` - Vault interface

### Test Files

**`test/absorb-test.ts`**
- Tests for the absorb mechanism
- Tests partial and full liquidations
- Tests reserve handling during absorption

**`test/buy-collateral-test.ts`**
- Tests for purchasing absorbed collateral
- Tests discount calculations

**`test/is-liquidatable-test.ts`**
- Tests for liquidation eligibility checks
- Tests collateralization calculations

**`test/quote-collateral-test.ts`**
- Tests for collateral purchase quotes

**`test/liquidation/liquidation-bot-test.ts`**
- Tests for the OnChainLiquidator contract
- Tests flash loan integration

### Scenario Files

**`scenario/LiquidationScenario.ts`**
- Property-based tests for liquidation mechanics
- Tests various liquidation scenarios

**`scenario/LiquidationBotScenario.ts`**
- Property-based tests for the liquidation bot
- Tests bot operations and profitability

### Related Scripts

**`scripts/liquidation_bot/`**
- `index.ts` - Main liquidation bot script
- `liquidateUnderwaterBorrowers.ts` - Core liquidation logic
- `deploy.ts` - Deployment script for liquidator contract

---

## 3. Governance & Configuration

### Overview
The Configurator contract manages protocol parameters and upgrades. It stores configuration and can deploy new Comet implementations.

### Primary Contract Files

**`contracts/Configurator.sol`**
- Main governance contract for managing Comet protocol
- **Configuration Management:**
  - `setConfiguration()` - Sets entire configuration for a Comet proxy
  - `getConfiguration()` - Retrieves current configuration
  - `setFactory()` - Sets the factory for deploying new implementations
- **Parameter Setters (governor-only):**
  - `setGovernor()` - Updates protocol governor
  - `setPauseGuardian()` - Updates pause guardian
  - `setBaseTokenPriceFeed()` - Updates base token price feed
  - `setSupplyKink()`, `setBorrowKink()` - Interest rate kink points
  - `setSupplyPerYearInterestRateSlopeLow/High()` - Supply rate slopes
  - `setBorrowPerYearInterestRateSlopeLow/High()` - Borrow rate slopes
  - `setTargetReserves()` - Target reserve amount
  - `addAsset()` - Adds new collateral asset
  - `updateAsset()` - Updates asset configuration
  - `updateAssetPriceFeed()` - Updates asset price feed
  - `updateAssetBorrowCollateralFactor()` - Updates borrow collateral factor
  - `updateAssetLiquidateCollateralFactor()` - Updates liquidation threshold
  - `updateAssetLiquidationFactor()` - Updates liquidation discount
  - `updateAssetSupplyCap()` - Updates supply cap
- **Upgrade Management:**
  - `deploy()` - Deploys new Comet implementation using factory

**`contracts/ConfiguratorStorage.sol`**
- Storage for Configurator contract
- Maps Comet proxy addresses to their configurations
- Stores factory addresses per Comet proxy

**`contracts/CometConfiguration.sol`**
- Defines configuration structs:
  - `Configuration` - Complete protocol configuration
  - `AssetConfig` - Per-asset configuration
- Used by both Comet and Configurator

**`contracts/CometFactory.sol`**
- Factory for deploying new Comet implementations
- `clone()` - Creates new Comet instance with given configuration
- Used by Configurator during upgrades

**`contracts/CometProxyAdmin.sol`**
- Proxy admin with upgrade functionality
- `deployAndUpgradeTo()` - Deploys new Comet and upgrades proxy in one transaction
- Extends OpenZeppelin's ProxyAdmin

**`contracts/ConfiguratorProxy.sol`**
- Proxy for Configurator contract
- Allows admin to call implementation directly

### Test Files

**`test/configurator-test.ts`**
- Comprehensive tests for Configurator functionality
- Tests all parameter setters
- Tests configuration management
- Tests upgrade process

**`test/pause-guardian-test.ts`**
- Tests for pause functionality
- Tests pause guardian permissions

### Scenario Files

**`scenario/ConfiguratorScenario.ts`**
- Property-based tests for configuration changes
- Tests governance operations

**`scenario/GovernanceScenario.ts`**
- Tests for governance proposals and execution
- Tests timelock operations

**`scenario/PauseGuardianScenario.ts`**
- Tests for pause/unpause operations
- Tests pause guardian permissions

### Related Files

**`deployments/*/migrations/*.ts`**
- Migration scripts that use Configurator to update protocol
- Examples of governance proposals

---

## 4. Rewards System

### Overview
CometRewards contract manages token rewards for protocol participants. Rewards are based on supply/borrow tracking indices.

### Primary Contract Files

**`contracts/CometRewards.sol`**
- Main rewards contract
- **Configuration:**
  - `setRewardConfig()` - Sets reward token for a Comet instance
  - `setRewardConfigWithMultiplier()` - Sets reward config with custom multiplier
- **Reward Claims:**
  - `claim()` - Claims rewards for a user
  - `claimTo()` - Claims rewards to a specific address
  - `claimRewards()` - Claims rewards for multiple Comet instances
- **Queries:**
  - `getRewardOwed()` - Gets amount of reward owed to a user
  - `getRewardOwedForAll()` - Gets rewards owed across all Comets
- **Tracking:**
  - Uses Comet's `baseTrackingSupplyIndex` and `baseTrackingBorrowIndex`
  - Calculates rewards based on user's accrued tracking amounts

### Test Files

**`test/rewards-test.ts`**
- Tests for reward calculations
- Tests reward claiming
- Tests reward configuration

**`test/base-tracking-accrued-test.ts`**
- Tests for base tracking accrual mechanics
- Tests tracking index calculations

### Scenario Files

**`scenario/RewardsScenario.ts`**
- Property-based tests for rewards
- Tests reward accrual and claiming

### Integration

Rewards integrate with:
- **Comet.sol** - Provides tracking indices via `baseTrackingSupplyIndex` and `baseTrackingBorrowIndex`
- **Bulker** - Can claim rewards as part of batch operations

---

## 5. Bulker (Batch Operations)

### Overview
Bulker contracts allow batching multiple Comet operations into a single transaction, saving gas and improving UX.

### Primary Contract Files

**`contracts/bulkers/BaseBulker.sol`**
- Base implementation for bulker functionality
- **Core Function:**
  - `invoke()` - Executes a list of actions in order
- **Supported Actions:**
  - `ACTION_SUPPLY_ASSET` - Supply collateral
  - `ACTION_SUPPLY_NATIVE_TOKEN` - Supply native token (ETH, etc.)
  - `ACTION_TRANSFER_ASSET` - Transfer collateral
  - `ACTION_WITHDRAW_ASSET` - Withdraw collateral
  - `ACTION_WITHDRAW_NATIVE_TOKEN` - Withdraw native token
  - `ACTION_CLAIM_REWARD` - Claim rewards
- **Helper Functions:**
  - `supplyTo()` - Supplies asset to Comet
  - `withdrawTo()` - Withdraws asset from Comet
  - `transferTo()` - Transfers asset in Comet
  - `claimReward()` - Claims rewards
  - `handleAction()` - Overridable for custom actions

**`contracts/bulkers/MainnetBulker.sol`**
- Mainnet-specific bulker implementation
- Extends BaseBulker with mainnet-specific functionality

**`contracts/bulkers/MainnetBulkerWithWstETHSupport.sol`**
- Bulker with wstETH support
- Handles wstETH wrapping/unwrapping

### Test Files

**`test/bulker-test.ts`**
- Comprehensive tests for bulker functionality
- Tests batching multiple operations
- Tests native token handling
- Tests reward claiming integration

### Scenario Files

**`scenario/BulkerScenario.ts`**
- Property-based tests for bulker operations
- Tests complex multi-action sequences

**`scenario/MainnetBulkerScenario.ts`**
- Tests for mainnet-specific bulker functionality

---

## 6. Cross-Chain Bridges

### Overview
Bridge receivers enable cross-chain governance by receiving messages from L1 and executing governance proposals on L2 chains.

### Primary Contract Files

**`contracts/bridges/BaseBridgeReceiver.sol`**
- Base contract for bridge receivers
- Handles cross-chain message verification
- Executes governance proposals on L2

**Chain-Specific Bridge Receivers:**

**`contracts/bridges/arbitrum/ArbitrumBridgeReceiver.sol`**
- Arbitrum-specific bridge receiver
- Uses Arbitrum's inbox for message verification

**`contracts/bridges/optimism/OptimismBridgeReceiver.sol`**
- Optimism-specific bridge receiver
- Uses Optimism's cross-domain messenger

**`contracts/bridges/base/BaseBridgeReceiver.sol`**
- Base (Coinbase L2) bridge receiver
- Uses Base's cross-domain messenger

**`contracts/bridges/polygon/PolygonBridgeReceiver.sol`**
- Polygon bridge receiver
- Uses Polygon's FxPortal

**`contracts/bridges/scroll/ScrollBridgeReceiver.sol`**
- Scroll bridge receiver
- Uses Scroll's messenger

**`contracts/bridges/linea/LineaBridgeReceiver.sol`**
- Linea bridge receiver
- Uses Linea's message service

**`contracts/bridges/mantle/`** (if exists)
- Mantle bridge receiver

**`contracts/bridges/ronin/RoninBridgeReceiver.sol`**
- Ronin bridge receiver

**`contracts/bridges/unichain/`** (if exists)
- Unichain bridge receiver

**`contracts/bridges/SweepableBridgeReceiver.sol`**
- Base class for sweepable bridge receivers
- Allows sweeping tokens from the contract

### Test Files

**`test/bridges/base-bridge-receiver-test.ts`**
- Tests for base bridge receiver functionality

**`test/bridges/sweepable-bridge-receiver-test.ts`**
- Tests for sweepable functionality

### Scenario Files

**`scenario/CrossChainGovernanceScenario.ts`**
- Property-based tests for cross-chain governance
- Tests bridge message relay and execution

### Related Utilities

**`scenario/utils/relay*.ts`**
- `relayMessage.ts` - Generic message relay
- `relayOptimismMessage.ts` - Optimism-specific relay
- `relayBaseMessage.ts` - Base-specific relay
- `relayArbitrumMessage.ts` - Arbitrum-specific relay
- `relayScrollMessage.ts` - Scroll-specific relay
- `relayLineaMessage.ts` - Linea-specific relay
- `relayPolygonMessage.ts` - Polygon-specific relay
- `relayRoninMessage.ts` - Ronin-specific relay
- `relayMantleMessage.ts` - Mantle-specific relay
- `relayUnichainMessage.ts` - Unichain-specific relay

**`scenario/utils/bridgeProposal.ts`**
- Utilities for creating cross-chain proposals

---

## 7. Price Feeds

### Overview
Price feeds provide asset prices to the protocol. Various implementations support different oracle types and price calculation methods.

### Primary Contract Files

**`contracts/utils/interfaces/IPriceFeed.sol`**
- Interface for price feeds
- `getPrice()` - Returns price in 8 decimals

**Standard Price Feeds:**

**`contracts/pricefeeds/ConstantPriceFeed.sol`**
- Returns a constant price
- Useful for testing or stable assets

**`contracts/pricefeeds/MultiplicativePriceFeed.sol`**
- Multiplies two price feeds
- Useful for derived prices (e.g., wstETH = stETH * exchange rate)

**`contracts/pricefeeds/ReverseMultiplicativePriceFeed.sol`**
- Divides two price feeds (reverse multiplication)
- Useful for inverse price calculations

**`contracts/pricefeeds/ScalingPriceFeed.sol`**
- Applies a scaling factor to a base price feed
- Useful for adjusting prices by a constant factor

**`contracts/pricefeeds/RateBasedScalingPriceFeed.sol`**
- Applies a time-based scaling rate
- Useful for assets with changing exchange rates

**Specialized Price Feeds:**

**`contracts/pricefeeds/WstETHPriceFeed.sol`**
- Price feed for wstETH (wrapped staked ETH)
- Combines stETH price with wstETH exchange rate

**`contracts/pricefeeds/WBTCPriceFeed.sol`**
- Price feed for WBTC
- Handles WBTC-specific price calculations

**`contracts/pricefeeds/EzETHExchangeRatePriceFeed.sol`**
- Price feed for ezETH
- Uses exchange rate from Renzo protocol

**`contracts/pricefeeds/RsETHScalingPriceFeed.sol`**
- Price feed for rsETH
- Uses scaling from Kelp DAO

**`contracts/pricefeeds/PriceFeedWith4626Support.sol`**
- Price feed for ERC-4626 vault tokens
- Calculates price based on vault shares and assets

### Test Files

**`test/price-feed-test.ts`**
- General price feed tests

**`test/pricefeeds/constant-price-feed-test.ts`**
- Tests for constant price feed

**`test/pricefeeds/multiplicative-price-feed.ts`**
- Tests for multiplicative price feed

**`test/pricefeeds/scaling-price-feed-test.ts`**
- Tests for scaling price feed

**`test/pricefeeds/wbtc-price-feed.ts`**
- Tests for WBTC price feed

**`test/pricefeeds/wsteth-price-feed.ts`**
- Tests for wstETH price feed

---

## 8. Asset Management

### Overview
Asset management includes adding/removing collateral assets and managing asset lists. Extended asset list support allows dynamic asset management.

### Primary Contract Files

**`contracts/AssetList.sol`**
- Contract for managing a list of assets
- Used when Comet needs to support more than the hardcoded 15 assets
- Provides dynamic asset list functionality

**`contracts/AssetListFactory.sol`**
- Factory for creating AssetList contracts

**`contracts/CometWithExtendedAssetList.sol`**
- Comet implementation with extended asset list support
- Allows more than 15 assets via external asset list contract

**`contracts/CometExtAssetList.sol`**
- Extension contract for Comet with asset list support

**`contracts/CometFactoryWithExtendedAssetList.sol`**
- Factory for deploying Comet with extended asset list

**`contracts/utils/interfaces/IAssetList.sol`**
- Interface for asset list contracts

**`contracts/utils/interfaces/IAssetListFactory.sol`**
- Interface for asset list factory

### Test Files

**`test/asset-info-test.ts`**
- Tests for asset information queries
- Tests asset configuration

**`test/asset-info-test-asset-list-comet.ts`**
- Tests for extended asset list functionality

**`test/update-assets-in-test.ts`**
- Tests for updating asset tracking

---

## 9. Interest Rate Model

### Overview
Comet uses a kinked interest rate model with separate rates for supply and borrow, each with low and high slopes around a kink point.

### Primary Contract Files

**`contracts/Comet.sol`**
- `accrueInterest()` - Accrues interest and updates indices
- `getSupplyRate()` - Calculates current supply interest rate
- `getBorrowRate()` - Calculates current borrow interest rate
- `getUtilization()` - Calculates current utilization ratio
- Interest rate parameters (immutable):
  - `supplyKink` - Kink point for supply rates
  - `supplyPerSecondInterestRateSlopeLow` - Supply rate slope below kink
  - `supplyPerSecondInterestRateSlopeHigh` - Supply rate slope above kink
  - `supplyPerSecondInterestRateBase` - Base supply rate
  - `borrowKink` - Kink point for borrow rates
  - `borrowPerSecondInterestRateSlopeLow` - Borrow rate slope below kink
  - `borrowPerSecondInterestRateSlopeHigh` - Borrow rate slope above kink
  - `borrowPerSecondInterestRateBase` - Base borrow rate

**`contracts/CometCore.sol`**
- `presentValue()` - Calculates present value of principal
- `presentValueSupply()` - Present value for supply positions
- `presentValueBorrow()` - Present value for borrow positions
- `principalValue()` - Converts present value to principal
- Index management for supply and borrow

**`contracts/CometStorage.sol`**
- `TotalsBasic` struct contains:
  - `baseSupplyIndex` - Current supply index
  - `baseBorrowIndex` - Current borrow index
  - `trackingSupplyIndex` - Supply tracking index for rewards
  - `trackingBorrowIndex` - Borrow tracking index for rewards
  - `lastAccrualTime` - Last time interest was accrued

**`contracts/CometMath.sol`**
- Math utilities for interest calculations
- Safe type conversions for indices

### Test Files

**`test/accrue-test.ts`**
- Tests for interest accrual
- Tests index updates
- Tests time-based calculations

**`test/interest-rate-test.ts`**
- Tests for interest rate calculations
- Tests kink model behavior
- Tests utilization-based rates

**`test/tracking-index-bounds-test.ts`**
- Tests for tracking index bounds
- Tests overflow/underflow protection

### Scenario Files

**`scenario/InterestRateScenario.ts`**
- Property-based tests for interest rates
- Tests various utilization scenarios

---

## 10. Testing Infrastructure

### Overview
The codebase uses Hardhat for testing with both unit tests and property-based scenario tests.

### Test Helpers

**`test/helpers.ts`**
- `makeProtocol()` - Creates a complete protocol instance for testing
- `makeConfigurator()` - Creates configurator and protocol
- `makeRewards()` - Creates rewards contract
- `makeBulker()` - Creates bulker contract
- Helper functions for common test setups

### Scenario Testing

**`scenario/`** directory contains property-based tests:

**Core Scenarios:**
- `CometScenario.ts` - General protocol scenarios
- `V2Scenario.ts` - V2 protocol scenarios

**Feature Scenarios:**
- `SupplyScenario.ts`, `WithdrawScenario.ts`, `TransferScenario.ts`
- `LiquidationScenario.ts`, `LiquidationBotScenario.ts`
- `RewardsScenario.ts`
- `InterestRateScenario.ts`
- `BulkerScenario.ts`
- `ConfiguratorScenario.ts`
- `GovernanceScenario.ts`
- `CrossChainGovernanceScenario.ts`
- `PauseGuardianScenario.ts`

**Scenario Context:**
- `scenario/context/CometContext.ts` - Main context class
- `scenario/context/CometActor.ts` - Actor (user) representation
- `scenario/context/CometAsset.ts` - Asset representation
- `scenario/context/Gov.ts` - Governance representation

**Scenario Constraints:**
- `scenario/constraints/` - Various constraint types for property testing
  - `CometBalanceConstraint.ts` - Balance constraints
  - `PriceConstraint.ts` - Price constraints
  - `UtilizationConstraint.ts` - Utilization constraints
  - `SupplyCapConstraint.ts` - Supply cap constraints
  - `ReservesConstraint.ts` - Reserve constraints
  - `PauseConstraint.ts` - Pause state constraints
  - And more...

**Scenario Utils:**
- `scenario/utils/` - Utility functions for scenarios
  - `scenarioHelper.ts` - General scenario helpers
  - `bridgeProposal.ts` - Bridge proposal utilities
  - `relay*.ts` - Message relay utilities for cross-chain tests

### Test Contracts

**`contracts/test/`** - Test-only contracts:
- `CometHarness.sol` - Harness for testing Comet internals
- `FaucetToken.sol` - Token with minting for tests
- `SimplePriceFeed.sol` - Simple price feed for tests
- `SimpleTimelock.sol` - Simple timelock for tests
- `GovernorSimple.sol` - Simple governor for tests
- And more...

---

## 11. Deployment Infrastructure

### Overview
Deployment scripts and configurations for deploying Comet to various networks.

### Deployment Structure

**`deployments/<network>/<market>/`**
- Each network (mainnet, arbitrum, base, etc.) has subdirectories for each market (usdc, weth, etc.)
- Contains:
  - `deploy.ts` - Main deployment script
  - `configuration.json` - Protocol configuration
  - `migrations/` - Migration scripts for protocol updates
  - `roots.json` - Root contract addresses (for spider)
  - `relations.json` - Contract relations (for spider)

### Deployment Scripts

**`src/deploy/Network.ts`**
- `deployNetworkComet()` - Main deployment function
- Handles deployment of all protocol contracts

**`plugins/deployment_manager/`**
- Deployment manager plugin for Hardhat
- Handles contract deployment, verification, and state management
- `Deploy.ts` - Core deployment logic

### Migration Scripts

**`deployments/*/migrations/*.ts`**
- Migration scripts for protocol updates
- Each migration has:
  - `prepare()` - Preparation step (can be async)
  - `enact()` - Actual migration execution
- Migrations are tested with scenarios before execution

### Deployment Networks

Supported networks (with deployment directories):
- **mainnet** - Ethereum mainnet
- **arbitrum** - Arbitrum L2
- **base** - Base L2
- **optimism** - Optimism L2
- **polygon** - Polygon
- **scroll** - Scroll L2
- **linea** - Linea L2
- **mantle** - Mantle L2
- **ronin** - Ronin
- **unichain** - Unichain
- **sepolia** - Sepolia testnet
- **fuji** - Avalanche Fuji testnet
- **hardhat** - Local Hardhat network

### Related Tools

**Spider Tool:**
- `tasks/spider/` - Spider task for crawling contract addresses
- Discovers related contracts from root addresses
- Generates `aliases.json` with all contract addresses

**Deployment Relations:**
- `deployments/relations.ts` - Defines contract relationships for spider

---

## Common Tasks & Tips

### Adding a New Collateral Asset

1. **Update Configuration:**
   - Use `Configurator.addAsset()` or `Configurator.updateAsset()`
   - Set price feed, collateral factors, liquidation factors, supply cap
   - See: `contracts/Configurator.sol`

2. **Deploy Price Feed:**
   - Create or use existing price feed in `contracts/pricefeeds/`
   - Ensure it implements `IPriceFeed` interface

3. **Test:**
   - Add tests in `test/asset-info-test.ts`
   - Add scenarios in relevant scenario files

### Modifying Interest Rate Model

1. **Update Parameters:**
   - Use Configurator setters for rate parameters
   - Parameters are immutable in Comet, so deploy new implementation
   - See: `contracts/Configurator.sol` setters for interest rates

2. **Test:**
   - Update `test/interest-rate-test.ts`
   - Add scenarios in `scenario/InterestRateScenario.ts`

### Adding a New Bridge

1. **Create Bridge Receiver:**
   - Extend `BaseBridgeReceiver.sol` or chain-specific base
   - Implement message verification for your chain
   - See examples in `contracts/bridges/`

2. **Add Relay Utility:**
   - Create relay utility in `scenario/utils/relay*.ts`
   - See existing examples for pattern

3. **Test:**
   - Add tests in `test/bridges/`
   - Add scenarios in `scenario/CrossChainGovernanceScenario.ts`

### Understanding Protocol State

**Key Storage Locations:**
- `CometStorage.sol` - All storage structures
- `Comet.totalsBasic()` - Market-wide state
- `Comet.userBasic()` - User base positions
- `Comet.userCollateral()` - User collateral balances

**Key Indices:**
- `baseSupplyIndex` - Tracks supply interest accrual
- `baseBorrowIndex` - Tracks borrow interest accrual
- `trackingSupplyIndex` - Tracks supply rewards accrual
- `trackingBorrowIndex` - Tracks borrow rewards accrual

### Debugging Tips

1. **Use Test Harnesses:**
   - `CometHarness.sol` exposes internal functions for testing
   - Useful for debugging specific behaviors

2. **Check Scenarios:**
   - Scenarios test many edge cases
   - Run `yarn scenario` to see property-based test results

3. **Review SPEC.md:**
   - `SPEC.md` contains formal protocol specification
   - Useful for understanding expected behavior

4. **Use Deployment Manager:**
   - Deployment manager provides utilities for interacting with deployed contracts
   - Useful for debugging on testnets

---

## File Organization Summary

```
contracts/
├── Comet*.sol              # Core protocol contracts
├── Configurator*.sol       # Governance contracts
├── CometRewards.sol        # Rewards contract
├── CometFactory*.sol       # Factory contracts
├── AssetList*.sol          # Asset management
├── bridges/                # Cross-chain bridges
├── bulkers/                # Batch operation contracts
├── liquidator/             # Liquidation bot
├── pricefeeds/             # Price feed implementations
├── test/                   # Test-only contracts
└── vendor/                 # Third-party contracts

test/
├── *-test.ts               # Unit tests by feature
├── helpers.ts              # Test utilities
└── liquidation/            # Liquidation test utilities

scenario/
├── *Scenario.ts            # Property-based tests
├── context/                 # Scenario context
├── constraints/             # Property constraints
└── utils/                   # Scenario utilities

deployments/
└── <network>/<market>/     # Deployment configs per network/market
    ├── deploy.ts
    ├── configuration.json
    └── migrations/
```

---

## Additional Resources

- **README.md** - General project overview and setup
- **SPEC.md** - Formal protocol specification
- **SCENARIO.md** - Scenario testing documentation
- **MIGRATIONS.md** - Migration process documentation
- **diagrams/** - UML diagrams for contract relationships

---

*Last updated: Based on current codebase structure*

