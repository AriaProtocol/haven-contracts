// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "contracts/test/CometHarness.sol";
import "contracts/CometExt.sol";
import "contracts/test/SimplePriceFeed.sol";
import "contracts/test/FaucetToken.sol";
import "contracts/CometConfiguration.sol";

contract Comet_Setup is Test, CometConfiguration {
    CometHarness public comet;
    CometExt public extensionDelegate;

    FaucetToken public baseToken;
    SimplePriceFeed public baseTokenPriceFeed;

    FaucetToken public weth;
    SimplePriceFeed public wethPriceFeed;

    FaucetToken public wbtc;
    SimplePriceFeed public wbtcPriceFeed;

    address public governor = address(0x1);
    address public pauseGuardian = address(0x2);

    uint64 public constant SUPPLY_KINK = 0.8e18;
    uint64 public constant SUPPLY_PER_YEAR_INTEREST_RATE_SLOPE_LOW = 0.05e18;
    uint64 public constant SUPPLY_PER_YEAR_INTEREST_RATE_SLOPE_HIGH = 2e18;
    uint64 public constant SUPPLY_PER_YEAR_INTEREST_RATE_BASE = 0;
    uint64 public constant BORROW_KINK = 0.8e18;
    uint64 public constant BORROW_PER_YEAR_INTEREST_RATE_SLOPE_LOW = 0.1e18;
    uint64 public constant BORROW_PER_YEAR_INTEREST_RATE_SLOPE_HIGH = 3e18;
    uint64 public constant BORROW_PER_YEAR_INTEREST_RATE_BASE = 0.005e18;
    uint64 public constant STORE_FRONT_PRICE_FACTOR = 0.5e18;
    uint64 public constant TRACKING_INDEX_SCALE = 1e15;
    uint64 public constant BASE_TRACKING_SUPPLY_SPEED = 1e15;
    uint64 public constant BASE_TRACKING_BORROW_SPEED = 1e15;
    uint104 public constant BASE_MIN_FOR_REWARDS = 1e6;
    uint104 public constant BASE_BORROW_MIN = 1e6;
    uint104 public constant TARGET_RESERVES = 0;

    bytes32 constant NAME32 = "Compound Comet";
    bytes32 constant SYMBOL32 = "cUSDC";

    function setUp() public virtual {
        deployComet();
    }

    function deployComet() public {
        // Deploy Base Token (USDC)
        baseToken = new FaucetToken(1000000 * 1e6, "USD Coin", 6, "USDC");
        baseTokenPriceFeed = new SimplePriceFeed(1e8, 8); // $1

        // Deploy WETH
        weth = new FaucetToken(1000 * 1e18, "Wrapped Ether", 18, "WETH");
        wethPriceFeed = new SimplePriceFeed(3_000 * 1e8, 8); // $3000

        // Deploy WBTC
        wbtc = new FaucetToken(100 * 1e8, "Wrapped Bitcoin", 8, "WBTC");
        wbtcPriceFeed = new SimplePriceFeed(90_000 * 1e8, 8); // $90000

        // Deploy Extension Delegate
        CometConfiguration.ExtConfiguration
            memory extConfig = CometConfiguration.ExtConfiguration({
                name32: NAME32,
                symbol32: SYMBOL32
            });
        extensionDelegate = new CometExt(extConfig);

        // Configure Assets
        AssetConfig[] memory assetConfigs = new AssetConfig[](2);

        // WETH Config
        assetConfigs[0] = AssetConfig({
            asset: address(weth),
            priceFeed: address(wethPriceFeed),
            decimals: 18,
            borrowCollateralFactor: 0.9e18,
            liquidateCollateralFactor: 0.95e18,
            liquidationFactor: 0.98e18,
            supplyCap: 100_000 ether
        });

        // WBTC Config
        assetConfigs[1] = AssetConfig({
            asset: address(wbtc),
            priceFeed: address(wbtcPriceFeed),
            decimals: 8,
            borrowCollateralFactor: 0.8e18,
            liquidateCollateralFactor: 0.85e18,
            liquidationFactor: 0.9e18,
            supplyCap: 10_000 * 1e8
        });

        // Configure Comet
        Configuration memory config = Configuration({
            governor: governor,
            pauseGuardian: pauseGuardian,
            baseToken: address(baseToken),
            baseTokenPriceFeed: address(baseTokenPriceFeed),
            extensionDelegate: address(extensionDelegate),
            supplyKink: SUPPLY_KINK,
            supplyPerYearInterestRateSlopeLow: SUPPLY_PER_YEAR_INTEREST_RATE_SLOPE_LOW,
            supplyPerYearInterestRateSlopeHigh: SUPPLY_PER_YEAR_INTEREST_RATE_SLOPE_HIGH,
            supplyPerYearInterestRateBase: SUPPLY_PER_YEAR_INTEREST_RATE_BASE,
            borrowKink: BORROW_KINK,
            borrowPerYearInterestRateSlopeLow: BORROW_PER_YEAR_INTEREST_RATE_SLOPE_LOW,
            borrowPerYearInterestRateSlopeHigh: BORROW_PER_YEAR_INTEREST_RATE_SLOPE_HIGH,
            borrowPerYearInterestRateBase: BORROW_PER_YEAR_INTEREST_RATE_BASE,
            storeFrontPriceFactor: STORE_FRONT_PRICE_FACTOR,
            trackingIndexScale: TRACKING_INDEX_SCALE,
            baseTrackingSupplySpeed: BASE_TRACKING_SUPPLY_SPEED,
            baseTrackingBorrowSpeed: BASE_TRACKING_BORROW_SPEED,
            baseMinForRewards: BASE_MIN_FOR_REWARDS,
            baseBorrowMin: BASE_BORROW_MIN,
            targetReserves: TARGET_RESERVES,
            assetConfigs: assetConfigs
        });

        // Deploy Comet
        comet = new CometHarness(config);

        // Initialize Storage
        comet.initializeStorage();

        // Labels
        vm.label(address(comet), "Comet");
        vm.label(address(baseToken), "USDC");
        vm.label(address(weth), "WETH");
        vm.label(address(wbtc), "WBTC");
        vm.label(governor, "Governor");
    }
}
