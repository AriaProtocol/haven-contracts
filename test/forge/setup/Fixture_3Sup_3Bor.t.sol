pragma solidity ^0.8.15;

import {Comet_Setup} from "test/forge/setup/Comet.setup.t.sol";

/// @dev Fixture data with 3 Suppliers, 4 Borrowers (one liquidated), 1 Liquidator
contract Fixture_3Sup_3Bor is Comet_Setup {
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

    function setUp() public override {
        super.setUp();

        setupSuppliers();
        setupBorrowers();

        weth.allocateTo(lastBorrower, 264e18);

        baseToken.allocateTo(address(comet), RESERVES); // Fund reserves

        _updateBorrowInvariant();
    }

    // Supply 3M
    function setupSuppliers() public {
        vm.label(supplier1, "Supplier 1");
        vm.label(supplier2, "Supplier 2");
        vm.label(supplier3, "Supplier 3");

        baseToken.allocateTo(supplier1, 1_000_000e6);
        baseToken.allocateTo(supplier2, 1_000_000e6);
        baseToken.allocateTo(supplier3, 1_000_000e6);

        vm.startPrank(supplier1);
        baseToken.approve(address(comet), 1_000_000e6);
        comet.supply(address(baseToken), 1_000_000e6);
        vm.stopPrank();

        vm.startPrank(supplier2);
        baseToken.approve(address(comet), 1_000_000e6);
        comet.supply(address(baseToken), 1_000_000e6);
        vm.stopPrank();

        vm.startPrank(supplier3);
        baseToken.approve(address(comet), 1_000_000e6);
        comet.supply(address(baseToken), 1_000_000e6);
        vm.stopPrank();
    }

    // Borrow 2.4M
    function setupBorrowers() public {
        vm.label(borrower1, "Borrower 1 (WBTC)");
        vm.label(borrower2, "Borrower 2 (WETH)");
        vm.label(borrower3, "Borrower 3 (Mixed)");

        // Borrower 1: WBTC
        // Needs > 800k borrow power. 15 WBTC * 90k * 0.8 = 1.08M
        wbtc.allocateTo(borrower1, 15e8);
        vm.startPrank(borrower1);
        wbtc.approve(address(comet), 15e8);
        comet.supply(address(wbtc), 15e8);
        comet.withdraw(address(baseToken), 800_000e6);
        vm.stopPrank();

        // Borrower 2: WETH
        // Needs > 800k borrow power. 350 WETH * 3k * 0.9 = 945k
        weth.allocateTo(borrower2, 350e18);
        vm.startPrank(borrower2);
        weth.approve(address(comet), 350e18);
        comet.supply(address(weth), 350e18);
        comet.withdraw(address(baseToken), 800_000e6);
        vm.stopPrank();

        // Borrower 3: Mixed
        // 10 WBTC * 90k * 0.8 = 720k
        // 100 WETH * 3k * 0.9 = 270k
        // Total = 990k
        wbtc.allocateTo(borrower3, 10e8);
        weth.allocateTo(borrower3, 100e18);
        vm.startPrank(borrower3);
        wbtc.approve(address(comet), 10e8);
        weth.approve(address(comet), 100e18);
        comet.supply(address(wbtc), 10e8);
        comet.supply(address(weth), 100e18);
        comet.withdraw(address(baseToken), 800_000e6);
        vm.stopPrank();
    }

    function test_SetUpState() public {
        uint256 totalSupply = comet.totalSupply();
        uint256 totalBorrow = comet.totalBorrow();

        // Suppliers supplied 3M
        assertApproxEqAbs(totalSupply, 3_000_000e6, 1000);

        // Borrowers borrowed 2.4M
        assertEq(totalBorrow, 2_400_000e6);

        // Utilization = 2.4M / 3.0M = 80%
        uint256 utilization = comet.getUtilization();
        assertApproxEqAbs(utilization, 0.8e18, 1e14);

        int256 reserves = comet.getReserves();
        emit log_named_int("Base reserves at start", reserves);
    }

    //============================================================================//
    //                                  INTERNAL                                  //
    //============================================================================//
    /// @dev only includes WETH and WBTC collateral
    function _updateBorrowInvariant() internal {
        invariant.totalBorrow = comet.totalBorrow();
        invariant.reserves = comet.getReserves();
        invariant.utilization = comet.getUtilization();

        _updateCollateralInvariant(address(weth));
        _updateCollateralInvariant(address(wbtc));
    }

    function _updateCollateralInvariant(address token) internal {
        (uint128 totalSupplyAsset,) = comet.totalsCollateral(token);
        invariant.collaterals[token].totalsCollateral = totalSupplyAsset;
        invariant.collaterals[token].collateralReserves = comet.getCollateralReserves(token);
    }
}
