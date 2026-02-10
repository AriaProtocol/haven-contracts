pragma solidity ^0.8.15;

import {CometExtInterface} from "contracts/CometExtInterface.sol";
import {CometMainInterface} from "contracts/CometMainInterface.sol";
import {CometStorage} from "contracts/CometStorage.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

/// @dev Internal _transferDebtOrSupply(...)
contract Comet_recover_Test is Fixture_3Sup_3Bor, CometStorage {
    address public newAddr = makeAddr("new address borrower3");

    // collateral previous data
    UserCollateral public lostWeth;
    UserCollateral public lostWbtc;

    // debt or supply previous data
    UserBasic public lostUserBasic;
    uint256 public lostAddrBorrow;

    ////// invariants
    // borrow
    uint256 public totalBorrow;
    mapping(address => TotalsCollateral) public totalsCollateral_;
    uint256 public wethCollateralReserves;
    uint256 public wbtcCollateralReserves;
    uint64 public borrowRate;
    // supply
    uint64 public supplyRate;
    uint256 public totalSupply;
    // shared
    int256 public reserves;
    uint256 utilization;

    function setUp() public override {
        super.setUp();

        _loadFixture(comet);
        _loadFixture(cometExtendedAssetList);
    }

    function test_recover_BorrowerCollateralAndDebt() public {
        vm.startPrank(recovererDelayed);

        // comet
        {
            bytes memory data = abi.encodeWithSelector(RECOVER_SELEC, borrower3, newAddr);
            governor.schedule(address(comet), data, 0);

            // setback required for recovererDelayed
            skip(RECOVER_DELAY);

            // snapshot AFTER the skip so accrued interest is captured
            _savePreviousCollateralData(address(comet));
            _savePreviousDebtOrSupplyData(comet);
            _savePreviousInvariantData(comet);

            comet.recover(borrower3, newAddr);

            _assert_collateralTransfered(address(comet), " - Comet.sol");
            _assert_DebtOrSupplyTransfered(comet, " - Comet.sol");
            _assertInvariant(comet, " - Comet.sol");
        }

        // cometExtendedAssetList
        {
            bytes memory dataExt = abi.encodeWithSelector(RECOVER_SELEC, borrower3, newAddr);
            governor.schedule(address(cometExtendedAssetList), dataExt, 0);

            // setback required for recovererDelayed
            skip(RECOVER_DELAY);

            // snapshot AFTER the skip so accrued interest is captured
            _savePreviousCollateralData(address(cometExtendedAssetList));
            _savePreviousDebtOrSupplyData(cometExtendedAssetList);
            _savePreviousInvariantData(cometExtendedAssetList);

            cometExtendedAssetList.recover(borrower3, newAddr);

            _assert_collateralTransfered(address(cometExtendedAssetList), " - CometExtendedWithAssetList.sol");
            _assert_DebtOrSupplyTransfered(cometExtendedAssetList, " - CometExtendedWithAssetList.sol");
            _assertInvariant(cometExtendedAssetList, " - CometExtendedWithAssetList.sol");
        }
    }

    //============================================= //
    // ============ Internal Functions ============ //
    //============================================= //
    function _assert_collateralTransfered(address cometX, string memory type_) internal {
        // newAddr has borrower3 collateral data
        {
            // WETH
            {
                UserCollateral memory newWeth;
                (newWeth.balance, newWeth._reserved) = _userCollateral(cometX, newAddr, address(weth));
                assertEq(newWeth.balance, lostWeth.balance, _concat("NewAddr DOES NOT have WETH as collateral", type_));
                assertEq(newWeth._reserved, lostWeth._reserved, _concat("NewAddr DOES NOT have WETH reserved", type_));
            }
            // WBTC
            {
                UserCollateral memory newWbtc;
                (newWbtc.balance, newWbtc._reserved) = _userCollateral(cometX, newAddr, address(wbtc));
                assertEq(newWbtc.balance, lostWbtc.balance, _concat("NewAddr DOES NOT have WBTC as collateral", type_));
                assertEq(newWbtc._reserved, lostWbtc._reserved, _concat("NewAddr DOES NOT have WBTC reserved", type_));
            }
        }

        // lost address collateral data reseted
        {
            // WETH
            {
                (lostWeth.balance, lostWeth._reserved) = _userCollateral(cometX, borrower3, address(weth));
                assertEq(lostWeth.balance, 0, _concat("Borrower3 WETH collateral NOT cleaned", type_));
                assertEq(lostWeth._reserved, 0, _concat("Borrower3 WETH reserved NOT cleaned", type_));
                assertEq(
                    CometExtInterface(cometX).collateralBalanceOf(borrower3, address(weth)),
                    0,
                    _concat("Borrower3 WETH => issue with collateralBalanceOf()", type_)
                );
            }
            // WBTC
            {
                (lostWbtc.balance, lostWbtc._reserved) = _userCollateral(cometX, borrower3, address(wbtc));
                assertEq(lostWbtc.balance, 0, _concat("Borrower3 WBTC collateral NOT cleaned", type_));
                assertEq(lostWbtc._reserved, 0, _concat("Borrower3 WBTC reserved NOT cleaned", type_));
                assertEq(
                    CometExtInterface(cometX).collateralBalanceOf(borrower3, address(wbtc)),
                    0,
                    _concat("Borrower3 WBTC => issue with collateralBalanceOf()", type_)
                );
            }
        }
    }

    function _assert_DebtOrSupplyTransfered(CometMainInterface cometX, string memory type_) internal {
        // after debt transfer
        assertEq(cometX.borrowBalanceOf(newAddr), lostAddrBorrow, _concat("Debt not transfered", type_));
        assertEq(cometX.borrowBalanceOf(borrower3), 0, _concat("LOST addr still has debt", type_));
        // UserBasic struct update checks
        {
            // newAddr has borrower3 data
            {
                UserBasic memory newUserBasic;
                newUserBasic = _userBasic(cometX, newAddr);
                assertEq(newUserBasic.principal, lostUserBasic.principal, _concat("NEW userBasic.principal", type_));
                assertEq(
                    newUserBasic.baseTrackingIndex,
                    lostUserBasic.baseTrackingIndex,
                    _concat("NEW userBasic.baseTrackingIndex", type_)
                );
                assertEq(
                    newUserBasic.baseTrackingAccrued,
                    lostUserBasic.baseTrackingAccrued,
                    _concat("NEW userBasic.baseTrackingAccrued", type_)
                );
                assertEq(newUserBasic.assetsIn, lostUserBasic.assetsIn, _concat("NEW userBasic.assetsIn", type_));
                assertEq(newUserBasic._reserved, lostUserBasic._reserved, _concat("NEW userBasic._reserved", type_));
            }

            // lost is completely reseted
            {
                lostUserBasic = _userBasic(cometX, borrower3);
                assertEq(lostUserBasic.principal, 0, _concat("LOST userBasic.principal", type_));
                assertEq(lostUserBasic.baseTrackingIndex, 0, _concat("LOST userBasic.baseTrackingIndex", type_));
                assertEq(lostUserBasic.baseTrackingAccrued, 0, _concat("LOST userBasic.baseTrackingAccrued", type_));
                assertEq(lostUserBasic.assetsIn, 0, _concat("LOST userBasic.assetsIn", type_));
                assertEq(lostUserBasic._reserved, 0, _concat("LOST userBasic._reserved", type_));
            }
        }
    }

    function _assertInvariant(CometMainInterface cometX, string memory type_) internal {
        assertEq(cometX.totalBorrow(), totalBorrow, _concat("totalBorrow invariant failed", type_));

        address wethAddr = address(weth);
        address wbtcAddr = address(wbtc);
        (uint256 totalSupplyAssetWeth, uint256 _reservedWeth) = cometX.totalsCollateral(wethAddr);
        (uint256 totalSupplyAssetWbtc, uint256 _reservedWbtc) = cometX.totalsCollateral(wbtcAddr);
        assertEq(
            totalSupplyAssetWeth,
            totalsCollateral_[wethAddr].totalSupplyAsset,
            _concat("totalsCollateral totalSupplyAsset WETH invariant failed", type_)
        );
        assertEq(
            _reservedWeth,
            totalsCollateral_[wethAddr]._reserved,
            _concat("totalsCollateral _reserved WETH invariant failed", type_)
        );
        assertEq(
            totalSupplyAssetWbtc,
            totalsCollateral_[wbtcAddr].totalSupplyAsset,
            _concat("totalsCollateral totalSupplyAsset WBTC invariant failed", type_)
        );
        assertEq(
            _reservedWbtc,
            totalsCollateral_[wbtcAddr]._reserved,
            _concat("totalsCollateral _reserved WBTC invariant failed", type_)
        );

        assertEq(
            cometX.getCollateralReserves(wethAddr),
            wethCollateralReserves,
            _concat("wethCollateralReserves invariant failed", type_)
        );
        assertEq(
            cometX.getCollateralReserves(wbtcAddr),
            wbtcCollateralReserves,
            _concat("wbtcCollateralReserves invariant failed", type_)
        );

        assertEq(
            cometX.getBorrowRate(cometX.getUtilization()), borrowRate, _concat("borrowRate invariant failed", type_)
        );

        assertEq(
            cometX.getSupplyRate(cometX.getUtilization()), supplyRate, _concat("supplyRate invariant failed", type_)
        );
        assertEq(cometX.totalSupply(), totalSupply, _concat("totalSupply invariant failed", type_));

        assertEq(cometX.getReserves(), reserves, _concat("reserves invariant failed", type_));
        assertEq(cometX.getUtilization(), utilization, _concat("utilization invariant failed", type_));
    }

    //-------------------- Utils --------------------//
    function _savePreviousCollateralData(address cometX) internal {
        (lostWeth.balance, lostWeth._reserved) = _userCollateral(cometX, borrower3, address(weth));
        (lostWbtc.balance, lostWbtc._reserved) = _userCollateral(cometX, borrower3, address(wbtc));
    }

    function _savePreviousDebtOrSupplyData(CometMainInterface cometX) internal {
        lostAddrBorrow = cometX.borrowBalanceOf(borrower3);
        lostUserBasic = _userBasic(cometX, borrower3);
    }

    function _savePreviousInvariantData(CometMainInterface cometX) internal {
        // borrow
        totalBorrow = cometX.totalBorrow();

        address wethAddr = address(weth);
        address wbtcAddr = address(wbtc);

        (totalsCollateral_[wethAddr].totalSupplyAsset, totalsCollateral_[wethAddr]._reserved) =
            cometX.totalsCollateral(address(wethAddr));
        (totalsCollateral_[wbtcAddr].totalSupplyAsset, totalsCollateral_[wbtcAddr]._reserved) =
            cometX.totalsCollateral(wbtcAddr);

        wethCollateralReserves = cometX.getCollateralReserves(wethAddr);
        wbtcCollateralReserves = cometX.getCollateralReserves(wbtcAddr);

        borrowRate = cometX.getBorrowRate(cometX.getUtilization());

        // supply
        supplyRate = cometX.getSupplyRate(cometX.getUtilization());
        totalSupply = cometX.totalSupply();

        // shared
        reserves = cometX.getReserves();
        utilization = cometX.getUtilization();
    }

    /// @dev userBasic is a public variable, but nt defined in any interface
    function _userBasic(CometMainInterface cometX, address user) internal returns (UserBasic memory userBasic) {
        bytes4 selector = bytes4(keccak256("userBasic(address)"));
        (, bytes memory data) = address(cometX).call(abi.encodeWithSelector(selector, user));

        (
            userBasic.principal,
            userBasic.baseTrackingIndex,
            userBasic.baseTrackingAccrued,
            userBasic.assetsIn,
            userBasic._reserved
        ) = abi.decode(data, (int104, uint64, uint64, uint16, uint8));
    }

    /// @dev userCollateral is a public variable, but nt defined in any interface
    function _userCollateral(address cometX, address user, address asset)
        internal
        returns (uint128 collateralBalance, uint128 reserved)
    {
        bytes4 selector = bytes4(keccak256("userCollateral(address,address)"));
        (, bytes memory data) = cometX.call(abi.encodeWithSelector(selector, user, asset));

        (collateralBalance, reserved) = abi.decode(data, (uint128, uint128));
    }
}
