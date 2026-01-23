pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {CometExtInterface} from "contracts/CometExtInterface.sol";
import {CometMainInterface} from "contracts/CometMainInterface.sol";
import {FaucetToken} from "contracts/test/FaucetToken.sol";

/// @dev Fixture data with 3 Suppliers, 4 Borrowers (one liquidated), 1 Liquidator
contract Fixture_3Sup_3Bor is Test {
    /// @dev so we dont have to pass it through all functions
    CometMainInterface private __comet;
    FaucetToken private __baseToken;
    FaucetToken private __weth;
    FaucetToken private __wbtc;

    address public supplier1 = address(0x101);
    address public supplier2 = address(0x102);
    address public supplier3 = address(0x103);

    address public borrower1 = address(0x201);
    address public borrower2 = address(0x202);
    address public borrower3 = address(0x203);

    address public lastBorrower = address(0x999);
    address public absorber = address(0x998);

    uint256 public constant RESERVES = 100_000 * 1e6;

    /// @dev Borrow invariant registered in setup
    struct BorrowInvariant {
        uint256 totalBorrow;
        mapping(address => CollateralData) collaterals;
        int256 reserves;
        uint256 utilization;
    }

    struct CollateralData {
        uint256 totalsCollateral;
        uint256 collateralReserves;
    }
    /// @dev must be in storage due to mapping
    BorrowInvariant public invariant;

    function test_SetUpState() public virtual {
        uint256 totalSupply = __comet.totalSupply();
        uint256 totalBorrow = __comet.totalBorrow();

        // Suppliers supplied 3M
        assertApproxEqAbs(totalSupply, 3_000_000e6, 1000);

        // Borrowers borrowed 2.4M
        assertEq(totalBorrow, 2_400_000e6);

        // Utilization = 2.4M / 3.0M = 80%
        uint256 utilization = __comet.getUtilization();
        assertApproxEqAbs(utilization, 0.8e18, 1e14);

        int256 reserves = __comet.getReserves();
        emit log_named_int("Base reserves at start", reserves);

        assertGe(
            CometExtInterface(address(__comet)).collateralBalanceOf(borrower3, address(__weth)),
            0,
            "Borrower3 DOES NOT have WETH as collateral"
        );
        assertGe(
            CometExtInterface(address(__comet)).collateralBalanceOf(borrower3, address(__wbtc)),
            0,
            "Borrower3 DOES NOT have WBTC as collateral"
        );
    }

    //============================================================================//
    //                                  INTERNAL                                  //
    //============================================================================//
    function _loadFixture(CometMainInterface _comet, FaucetToken _baseToken, FaucetToken _weth, FaucetToken _wbtc)
        internal
    {
        __comet = _comet;
        __baseToken = _baseToken;
        __weth = _weth;
        __wbtc = _wbtc;

        _setupSuppliers();
        _setupBorrowers();

        __weth.allocateTo(lastBorrower, 264e18);

        __baseToken.allocateTo(address(__comet), RESERVES); // Fund reserves

        _updateBorrowInvariant();
    }

    // Supply 3M
    function _setupSuppliers() internal {
        vm.label(supplier1, "Supplier 1");
        vm.label(supplier2, "Supplier 2");
        vm.label(supplier3, "Supplier 3");

        __baseToken.allocateTo(supplier1, 1_000_000e6);
        __baseToken.allocateTo(supplier2, 1_000_000e6);
        __baseToken.allocateTo(supplier3, 1_000_000e6);

        vm.startPrank(supplier1);
        __baseToken.approve(address(__comet), 1_000_000e6);
        __comet.supply(address(__baseToken), 1_000_000e6);
        vm.stopPrank();

        vm.startPrank(supplier2);
        __baseToken.approve(address(__comet), 1_000_000e6);
        __comet.supply(address(__baseToken), 1_000_000e6);
        vm.stopPrank();

        vm.startPrank(supplier3);
        __baseToken.approve(address(__comet), 1_000_000e6);
        __comet.supply(address(__baseToken), 1_000_000e6);
        vm.stopPrank();
    }

    // Borrow 2.4M
    function _setupBorrowers() internal {
        vm.label(borrower1, "Borrower 1 (WBTC)");
        vm.label(borrower2, "Borrower 2 (WETH)");
        vm.label(borrower3, "Borrower 3 (Mixed)");

        // Borrower 1: WBTC
        // Needs > 800k borrow power. 15 WBTC * 90k * 0.8 = 1.08M
        __wbtc.allocateTo(borrower1, 15e8);
        vm.startPrank(borrower1);
        __wbtc.approve(address(__comet), 15e8);
        __comet.supply(address(__wbtc), 15e8);
        __comet.withdraw(address(__baseToken), 800_000e6);
        vm.stopPrank();

        // Borrower 2: WETH
        // Needs > 800k borrow power. 350 WETH * 3k * 0.9 = 945k
        __weth.allocateTo(borrower2, 350e18);
        vm.startPrank(borrower2);
        __weth.approve(address(__comet), 350e18);
        __comet.supply(address(__weth), 350e18);
        __comet.withdraw(address(__baseToken), 800_000e6);
        vm.stopPrank();

        // Borrower 3: Mixed
        // 10 WBTC * 90k * 0.8 = 720k
        // 100 WETH * 3k * 0.9 = 270k
        // Total = 990k
        __wbtc.allocateTo(borrower3, 10e8);
        __weth.allocateTo(borrower3, 100e18);
        vm.startPrank(borrower3);
        __wbtc.approve(address(__comet), 10e8);
        __weth.approve(address(__comet), 100e18);
        __comet.supply(address(__wbtc), 10e8);
        __comet.supply(address(__weth), 100e18);
        __comet.withdraw(address(__baseToken), 800_000e6);
        vm.stopPrank();
    }

    /// @dev only includes WETH and WBTC collateral
    function _updateBorrowInvariant() internal {
        invariant.totalBorrow = __comet.totalBorrow();
        invariant.reserves = __comet.getReserves();
        invariant.utilization = __comet.getUtilization();

        ___updateCollateralInvariant(address(__weth));
        ___updateCollateralInvariant(address(__wbtc));
    }

    //===========================================================================//
    //                                  PRIVATE                                  //
    //===========================================================================//
    function ___updateCollateralInvariant(address token) private {
        invariant.collaterals[token].collateralReserves = __comet.getCollateralReserves(token);

        (, bytes memory data) = address(__comet).staticcall(abi.encodeWithSignature("totalsCollateral(address)", token));
        (uint128 totalSupplyAsset,) = abi.decode(data, (uint128, uint128));
        invariant.collaterals[token].totalsCollateral = totalSupplyAsset;
    }
}
