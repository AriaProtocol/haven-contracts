// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

/// @dev solely testing fixture setup state
contract Fixture_3Sup_3Bor_Test is Fixture_3Sup_3Bor {
    function test_SetUpState_Fixtures_3Sup_3Bor() public virtual {
        _loadFixture(comet);

        uint256 totalSupply = comet.totalSupply();
        uint256 totalBorrow = comet.totalBorrow();

        // Suppliers supplied 3M
        assertApproxEqAbs(totalSupply, 3_000_000e6, 1000, "total supply mismatch");

        // Borrowers borrowed 2.4M
        assertApproxEqAbs(totalBorrow, 2_400_000e6, 1, "total borrow mismatch");

        // Utilization = 2.4M / 3.0M = 80%
        uint256 utilization = comet.getUtilization();
        assertApproxEqAbs(utilization, 0.8e18, 1e14, "utilization mismatch");

        int256 reserves = comet.getReserves();
        emit log_named_int("Base reserves at start", reserves);

        assertGe(
            CometExtInterface(address(comet)).collateralBalanceOf(borrower3, address(weth)),
            0,
            "Borrower3 DOES NOT have WETH as collateral"
        );
        assertGe(
            CometExtInterface(address(comet)).collateralBalanceOf(borrower3, address(wbtc)),
            0,
            "Borrower3 DOES NOT have WBTC as collateral"
        );
    }
}
