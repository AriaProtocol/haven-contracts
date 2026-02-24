// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Strings} from "oz/utils/Strings.sol";

import {CometHarness} from "contracts/test/CometHarness.sol";
import {CometHarnessExtendedAssetList} from "contracts/test/CometHarnessExtendedAssetList.sol";
import {CometExtAssetList} from "contracts/CometExtAssetList.sol";
import {AssetListFactory} from "contracts/AssetListFactory.sol";

import "forge-std/Test.sol";
import "contracts/CometExt.sol";
import "contracts/CometConfiguration.sol";
import "contracts/test/CometHarness.sol";
import "contracts/test/SimplePriceFeed.sol";
import "contracts/test/FaucetToken.sol";

import {AccessManagerSingleAdmin} from "aria/access/AccessManagerSingleAdmin.sol";

contract Common_Setup is Test, CometConfiguration {
    using Strings for uint256;

    AccessManagerSingleAdmin public governor;
    CometHarness public comet;
    CometHarnessExtendedAssetList public cometExtendedAssetList;

    //////// tokens & feeds ////////
    FaucetToken public baseToken;
    SimplePriceFeed public baseTokenPriceFeed;
    FaucetToken public weth;
    SimplePriceFeed public wethPriceFeed;
    FaucetToken public wbtc;
    SimplePriceFeed public wbtcPriceFeed;
    FaucetToken[] public extraTokens;

    //////// users ////////
    address public accessManagerAdmin;
    address public liquidator;
    address public pauser; // in AccessManager, rather than Comet
    address public pauseGuardian; // in AccessManager, rather than Comet
    address public notRecoverer;
    address public recovererDelayed;
    address public withdrawer;

    //////// roles ////////
    uint64 public constant PAUSE_ROLE = 1;
    uint64 public constant LIQUIDATOR_ROLE = 2;
    uint64 public constant RECOVERER_ROLE = 3;
    uint64 public constant PAUSE_GUARDIAN = 4;
    uint64 public constant WITHDRAWER_ROLE = 5;

    //////// market config ////////
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

    // delays
    uint48 public constant ADMIN_TRANSFER_DELAY = 2 days;
    uint32 public constant RECOVERER_GRANT_DELAY = 12 hours;
    uint32 public constant WITHDRAWER_GRANT_DELAY = 6 days;
    uint32 public constant PAUSE_DELAY = 1;
    uint32 public constant LIQUIDATOR_DELAY = 1;
    uint32 public constant RECOVER_DELAY = 1 days;
    uint32 public constant WITHDRAWER_DELAY = 7 days;

    //////// FUNCTION SELECTORS ////////
    // 0x44c35d07
    bytes4 public PAUSE_SELEC = CometMainInterface.pause.selector;
    // 0xc3cecfd2
    bytes4 public ABSORB_SELEC = CometMainInterface.absorb.selector;
    // 0xe4e6e779
    bytes4 public BUY_COLL_SELEC = CometMainInterface.buyCollateral.selector;
    bytes4 public RECOVER_SELEC = CometMainInterface.recover.selector;
    bytes4 public WITHDRAW_SELECT = CometMainInterface.withdrawReserves.selector;

    AssetConfig[] private __assetsConfig;
    AssetConfig[] private __assetsConfigExtended;
    bytes4[] internal _selectors; // easier to add data

    function setUp() public virtual {
        // shared setup
        __createAddr();
        __deployTokensAndPriceFeed();

        // standard Comet
        __assetsConfig = __configureAssets();
        address cometExt_ = _deployCometExt();
        Configuration memory config_ = __configureComet(cometExt_, __assetsConfig);
        comet = _deployComet(config_);
        __defineRolesAndGrantDefaultAccess(address(comet));

        // extended asset list Comet
        __assetsConfigExtended = __configureAssetsExtended();
        cometExt_ = _deployCometExt_ExtendedAssetList();
        config_ = __configureComet(cometExt_, __assetsConfigExtended);
        cometExtendedAssetList = _deployComet_ExtendedAssetList(config_);
        __defineRolesAndGrantDefaultAccess(address(cometExtendedAssetList));

        ___labelAddresses();
    }

    ////////////////////////////////////////////////////////////////
    //////// Deploy markets, which contains everything else ////////
    ////////////////////////////////////////////////////////////////
    function _deployComet(Configuration memory config_) internal returns (CometHarness comet_) {
        comet_ = new CometHarness(config_);
        comet_.initializeStorage();
    }

    function _deployComet_ExtendedAssetList(Configuration memory config_)
        internal
        returns (CometHarnessExtendedAssetList cometExtAsset_)
    {
        cometExtAsset_ = new CometHarnessExtendedAssetList(config_);
        cometExtAsset_.initializeStorage();
    }

    ////////////////////////////////////////////////////////////////
    //// Deploy extension delegates, which contains hToken info ////
    ////////////////////////////////////////////////////////////////
    function _deployCometExt() internal returns (address) {
        CometConfiguration.ExtConfiguration memory extConfig =
            CometConfiguration.ExtConfiguration({name32: "Compound Comet", symbol32: "cUSDC"});
        return address(new CometExt(extConfig));
    }

    function _deployCometExt_ExtendedAssetList() internal returns (address) {
        CometConfiguration.ExtConfiguration memory extConfig = CometConfiguration.ExtConfiguration({
            name32: "Compound Comet_ExtendedAssetList", symbol32: "cUSDC_ExtendedAssetList"
        });

        return address(new CometExtAssetList(extConfig, address(new AssetListFactory())));
    }

    //==========================================================================//
    //                                 PRIVATE                                  //
    //==========================================================================//
    function __configureAssets() private returns (AssetConfig[] memory config) {
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

    function __configureAssetsExtended() private returns (AssetConfig[] memory config) {
        config = new AssetConfig[](20);

        config[0] = __assetsConfig[0];
        config[1] = __assetsConfig[1];

        FaucetToken newToken;
        string memory number;
        uint64 borrowCF;
        uint64 liquidateCF;
        uint64 liquidationF;

        for (uint16 i = 2; i < 20; ++i) {
            number = uint256(i).toString();
            newToken = new FaucetToken(0, string.concat(number, "Coin"), 18, string.concat(number, "C"));

            extraTokens.push(newToken);

            // Calculate collateral factors: base + i%
            // For i=2: 52%, 57%, 62%; for i=19: 69%, 74%, 79%
            uint64 borrowCF = uint64((50 * 1e16) + (uint256(i) * 1e16));
            uint64 liquidateCF = uint64((55 * 1e16) + (uint256(i) * 1e16));
            uint64 liquidationF = uint64((60 * 1e16) + (uint256(i) * 1e16));

            config[i] = AssetConfig({
                asset: address(newToken),
                priceFeed: address(new SimplePriceFeed(int(uint(i)) * 1e8, 8)),
                decimals: 18,
                borrowCollateralFactor: borrowCF,
                liquidateCollateralFactor: liquidateCF,
                liquidationFactor: liquidationF,
                supplyCap: 100_000 * 1e18
            });
        }
    }

    function __configureComet(address extensionDelegate_, AssetConfig[] memory assetsConfig_)
        private
        returns (Configuration memory config)
    {
        config = Configuration({
            governor: address(governor),
            pauseGuardian: address(0),
            baseToken: address(baseToken),
            baseTokenPriceFeed: address(baseTokenPriceFeed),
            extensionDelegate: extensionDelegate_,
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
            assetConfigs: assetsConfig_
        });
    }

    function __createAddr() private {
        accessManagerAdmin = makeAddr("accessManagerAdmin");
        liquidator = makeAddr("liquidator");
        pauser = makeAddr("pauser");
        pauseGuardian = makeAddr("pauseGuardian");
        notRecoverer = makeAddr("notRecoverer");
        withdrawer = makeAddr("withdrawer");
        recovererDelayed = makeAddr("recovererDelayed");

        governor = new AccessManagerSingleAdmin(ADMIN_TRANSFER_DELAY, accessManagerAdmin);
    }

    function __defineRolesAndGrantDefaultAccess(address comet) private {
        vm.startPrank(accessManagerAdmin);

        // set roles on selector & configure delays
        {
            _selectors.push(PAUSE_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, PAUSE_ROLE);
            governor.setRoleGuardian(PAUSE_ROLE, PAUSE_GUARDIAN);
            governor.setExecutionDelay(PAUSE_ROLE, PAUSE_DELAY);
            delete _selectors;

            _selectors.push(ABSORB_SELEC);
            _selectors.push(BUY_COLL_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, LIQUIDATOR_ROLE);
            governor.setExecutionDelay(LIQUIDATOR_ROLE, LIQUIDATOR_DELAY);
            delete _selectors;

            _selectors.push(RECOVER_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, RECOVERER_ROLE);
            governor.setGrantDelay(RECOVERER_ROLE, RECOVERER_GRANT_DELAY);
            governor.setExecutionDelay(RECOVERER_ROLE, RECOVER_DELAY);
            delete _selectors;

            _selectors.push(WITHDRAW_SELECT);
            governor.setTargetFunctionRole(comet, _selectors, WITHDRAWER_ROLE);
            governor.setGrantDelay(WITHDRAWER_ROLE, WITHDRAWER_GRANT_DELAY);
            governor.setExecutionDelay(WITHDRAWER_ROLE, WITHDRAWER_DELAY);
            delete _selectors;

            // timepoint when new grant/execution delays apply
            skip(WITHDRAWER_GRANT_DELAY + WITHDRAWER_DELAY);
        }

        // grant roles (execution delay is per-role, set above)
        {
            governor.grantRole(PAUSE_ROLE, pauser);
            governor.grantRole(LIQUIDATOR_ROLE, liquidator);
            governor.grantRole(RECOVERER_ROLE, recovererDelayed);
            governor.grantRole(PAUSE_GUARDIAN, pauseGuardian);
            governor.grantRole(WITHDRAWER_ROLE, withdrawer);
            // skip for grant delays to take effect
            skip(WITHDRAWER_GRANT_DELAY + WITHDRAWER_DELAY);
        }

        vm.stopPrank();
    }

    function __deployTokensAndPriceFeed() private {
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

    function ___labelAddresses() internal {
        vm.label(address(comet), "Comet");
        vm.label(address(cometExtendedAssetList), "CometExtendedAssetList");
        vm.label(address(baseToken), "USDC");
        vm.label(address(weth), "WETH");
        vm.label(address(wbtc), "WBTC");
        vm.label(address(governor), "Governor");
        vm.label(accessManagerAdmin, "Access Admin");
        vm.label(liquidator, "Liquidator");
        vm.label(pauser, "Pauser");
        vm.label(notRecoverer, "Not Recoverer");
        vm.label(pauseGuardian, "Pause Guardian");
        vm.label(withdrawer, "Withdrawer");
    }

    ////// Utils //////
    function _concat(string memory str1, string memory str2) internal pure returns (string memory) {
        return string.concat(str1, str2);
    }
}
