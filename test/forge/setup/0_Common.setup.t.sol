// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "contracts/CometExt.sol";
import "contracts/CometConfiguration.sol";
import "contracts/test/CometHarness.sol";
import "contracts/test/SimplePriceFeed.sol";
import "contracts/test/FaucetToken.sol";

import {AccessManager} from "oz/access/manager/AccessManager.sol";

contract Common_Setup is Test, CometConfiguration {
    AccessManager public governor;
    CometExt public extensionDelegate;

    FaucetToken public baseToken;
    SimplePriceFeed public baseTokenPriceFeed;

    FaucetToken public weth;
    SimplePriceFeed public wethPriceFeed;

    FaucetToken public wbtc;
    SimplePriceFeed public wbtcPriceFeed;

    address public accessManagerAdmin;
    address public liquidator;
    address public pauseGuardian;
    address public recoverer;

    uint64 public constant PAUSE_ROLE = 1;
    uint64 public constant LIQUIDATOR_ROLE = 2;
    uint64 public constant RECOVERER_ROLE = 3;

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

    // 0x44c35d07
    bytes4 public PAUSE_SELEC = _compSelector("pause(bool,bool,bool,bool,bool)");
    // 0xc3cecfd2
    bytes4 public ABSORB_SELEC = _compSelector("absorb(address,address[])");
    // 0xe4e6e779
    bytes4 public BUY_COLL_SELEC = _compSelector("buyCollateral(address,uint256,uint256,address)");
    bytes4 public RECOVER_SELEC = _compSelector("recover(address,address)");

    function setUp() public virtual {
        _createAddr();

        _deployTokensAndPriceFeed();
        _deployCometExt();

        _deployComet();

        // Labels
        vm.label(address(baseToken), "USDC");
        vm.label(address(weth), "WETH");
        vm.label(address(wbtc), "WBTC");
        vm.label(address(governor), "Governor");
        vm.label(accessManagerAdmin, "Access Admin");
        vm.label(liquidator, "Liquidator");
        vm.label(recoverer, "Recoverer");
    }

    function _createAddr() internal {
        accessManagerAdmin = makeAddr("accessManagerAdmin");
        liquidator = makeAddr("liquidator");
        pauseGuardian = makeAddr("pauseGuardian");
        recoverer = makeAddr("recoverer");

        governor = new AccessManager(accessManagerAdmin);
    }

    function _deployComet() internal virtual {}

    function _deployCometExt() internal virtual {}

    function _deployTokensAndPriceFeed() internal {
        // Deploy Base Token (USDC)
        baseToken = new FaucetToken(1000000 * 1e6, "USD Coin", 6, "USDC");
        baseTokenPriceFeed = new SimplePriceFeed(1e8, 8); // $1

        // Deploy WETH
        weth = new FaucetToken(1000 * 1e18, "Wrapped Ether", 18, "WETH");
        wethPriceFeed = new SimplePriceFeed(3_000 * 1e8, 8); // $3000

        // Deploy WBTC
        wbtc = new FaucetToken(100 * 1e8, "Wrapped Bitcoin", 8, "WBTC");
        wbtcPriceFeed = new SimplePriceFeed(90_000 * 1e8, 8); // $90000
    }

    function _configureAssets() internal returns (AssetConfig[] memory config) {
        config = new AssetConfig[](2);

        // WETH Config
        config[0] = AssetConfig({
            asset: address(weth),
            priceFeed: address(wethPriceFeed),
            decimals: 18,
            borrowCollateralFactor: 0.9e18,
            liquidateCollateralFactor: 0.95e18,
            liquidationFactor: 0.98e18,
            supplyCap: 100_000 ether
        });

        // WBTC Config
        config[1] = AssetConfig({
            asset: address(wbtc),
            priceFeed: address(wbtcPriceFeed),
            decimals: 8,
            borrowCollateralFactor: 0.8e18,
            liquidateCollateralFactor: 0.85e18,
            liquidationFactor: 0.9e18,
            supplyCap: 10_000 * 1e8
        });
    }

    function _configureComet() internal returns (Configuration memory config) {
        config = Configuration({
            governor: address(governor),
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
            assetConfigs: _configureAssets()
        });
    }

    //////// MUST BE called in child contracts ////////
    bytes4[] internal _selectors; // easier to add data

    function _defineRolesAndGrantDefaultAccess(address comet) internal {
        vm.startPrank(accessManagerAdmin);

        // set roles on selector
        {
            _selectors.push(PAUSE_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, PAUSE_ROLE);
            governor.setRoleGuardian(PAUSE_ROLE, PAUSE_ROLE);
            delete _selectors;

            _selectors.push(ABSORB_SELEC);
            _selectors.push(BUY_COLL_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, LIQUIDATOR_ROLE);
            delete _selectors;

            _selectors.push(RECOVER_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, RECOVERER_ROLE);
            delete _selectors;
            governor.setGrantDelay(RECOVERER_ROLE, 12 hours);
            // timepoint when new grant delay appilies (minSetBack used as new delay is lower)
            skip(governor.minSetback());
        }

        // grant roles
        {
            governor.grantRole(PAUSE_ROLE, pauseGuardian, 0);
            governor.grantRole(LIQUIDATOR_ROLE, liquidator, 0);
            governor.grantRole(RECOVERER_ROLE, recoverer, 1 days);
            // new delay for recoverer role to apply
            skip(12 hours);
        }

        vm.stopPrank();
    }

    function _compSelector(string memory sel_) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sel_)));
    }
}
