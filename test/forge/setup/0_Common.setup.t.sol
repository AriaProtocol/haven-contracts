// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

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

import {AccessManager} from "oz/access/manager/AccessManager.sol";

contract Common_Setup is Test, CometConfiguration {
    AccessManager public governor;
    CometHarness public comet;
    CometHarnessExtendedAssetList public cometExtendedAssetList;

    //////// tokens & feeds ////////
    FaucetToken public baseToken;
    SimplePriceFeed public baseTokenPriceFeed;
    FaucetToken public weth;
    SimplePriceFeed public wethPriceFeed;
    FaucetToken public wbtc;
    SimplePriceFeed public wbtcPriceFeed;

    //////// users ////////
    address public accessManagerAdmin;
    address public liquidator;
    address public pauseGuardian; // in AccessManager, rather than Comet
    address public recoverer;
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

    //////// FUNCTION SELECTORS ////////
    // 0x44c35d07
    bytes4 public PAUSE_SELEC = _compSelector("pause(bool,bool,bool,bool,bool)");
    // 0xc3cecfd2
    bytes4 public ABSORB_SELEC = _compSelector("absorb(address,address[])");
    // 0xe4e6e779
    bytes4 public BUY_COLL_SELEC = _compSelector("buyCollateral(address,uint256,uint256,address)");
    bytes4 public RECOVER_SELEC = _compSelector("recover(address,address)");
    bytes4 public WITHDRAW_SELECT = _compSelector("withdrawReserves(address,uint256)");

    AssetConfig[] private __assetsConfig;
    bytes4[] internal _selectors; // easier to add data

    function setUp() public virtual {
        // shared setup
        __createAddr();
        __deployTokensAndPriceFeed();
        __assetsConfig = __configureAssets();

        // standard Comet
        address cometExt_ = _deployCometExt();
        Configuration memory config_ = __configureComet(cometExt_);
        comet = _deployComet(config_);
        __defineRolesAndGrantDefaultAccess(address(comet));

        // extended asset list Comet
        cometExt_ = _deployCometExt_ExtendedAssetList();
        config_ = __configureComet(cometExt_);
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

    //// PURE
    function _compSelector(string memory sel_) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sel_)));
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

    function __configureComet(address extensionDelegate_) private returns (Configuration memory config) {
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
            assetConfigs: __assetsConfig
        });
    }

    function __createAddr() private {
        accessManagerAdmin = makeAddr("accessManagerAdmin");
        liquidator = makeAddr("liquidator");
        pauseGuardian = makeAddr("pauseGuardian");
        recoverer = makeAddr("recoverer");
        withdrawer = makeAddr("withdrawer");

        governor = new AccessManager(accessManagerAdmin);
    }

    function __defineRolesAndGrantDefaultAccess(address comet) private {
        vm.startPrank(accessManagerAdmin);

        // set roles on selector
        {
            _selectors.push(PAUSE_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, PAUSE_ROLE);
            governor.setRoleGuardian(PAUSE_ROLE, PAUSE_GUARDIAN);
            delete _selectors;

            _selectors.push(ABSORB_SELEC);
            _selectors.push(BUY_COLL_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, LIQUIDATOR_ROLE);
            delete _selectors;

            _selectors.push(RECOVER_SELEC);
            governor.setTargetFunctionRole(comet, _selectors, RECOVERER_ROLE);
            delete _selectors;
            governor.setGrantDelay(RECOVERER_ROLE, 12 hours);

            _selectors.push(WITHDRAW_SELECT);
            governor.setTargetFunctionRole(comet, _selectors, WITHDRAWER_ROLE);
            delete _selectors;
            governor.setGrantDelay(WITHDRAWER_ROLE, 6 days);

            // timepoint when new grant delay appilies, both for recoverer and withdrawer
            skip(6 days);
        }

        // grant roles
        {
            governor.grantRole(PAUSE_ROLE, pauseGuardian, 0);
            governor.grantRole(LIQUIDATOR_ROLE, liquidator, 0);
            governor.grantRole(RECOVERER_ROLE, recoverer, 1 days);
            governor.grantRole(PAUSE_GUARDIAN, pauseGuardian, 0);
            governor.grantRole(WITHDRAWER_ROLE, withdrawer, 7 days);
            // new delay for roles effect
            skip(6 days);
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
        vm.label(recoverer, "Recoverer");
        vm.label(pauseGuardian, "Pause Guardian");
        vm.label(withdrawer, "Withdrawer");
    }

    ////// Utils //////
    function _concat(string memory str1, string memory str2) internal pure returns (string memory) {
        return string.concat(str1, str2);
    }
}
