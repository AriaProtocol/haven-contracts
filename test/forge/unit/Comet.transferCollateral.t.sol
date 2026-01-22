pragma solidity ^0.8.15;

import {CometExtInterface} from "contracts/CometExtInterface.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/Fixture_3Sup_3Bor.t.sol";

contract Comet_transferCollateral_Test is Fixture_3Sup_3Bor {
    address public newAddr = makeAddr("new address borrower3");

    CometExtInterface public cometExt;

    uint16 assetsIn;

    function setUp() public override {
        super.setUp();

        cometExt = CometExtInterface(address(comet));

        (,,, assetsIn,) = comet.userBasic(borrower3);
    }

    function test_SetUpState() public override {
        super.test_SetUpState();

        assertGe(
            cometExt.collateralBalanceOf(borrower3, address(weth)), 0, "Borrower3 DOES NOT have WETH as collateral"
        );
        assertGe(
            cometExt.collateralBalanceOf(borrower3, address(wbtc)), 0, "Borrower3 DOES NOT have WBTC as collateral"
        );
    }

    function test_transferCollateral() public {
        // collateral before admin transfer
        (uint128 lostWethCollBalance, uint128 lostCollWeth_reserved) = cometExt.userCollateral(borrower3, address(weth));
        (uint128 lostWbtcCollBalance, uint128 lostCollWbtc_reserved) = cometExt.userCollateral(borrower3, address(wbtc));

        comet.exposed_transferCollateral(borrower3, newAddr);

        // newAddr has borrower3 collateral
        {}

        // lost address does not have any collateral
        {}
    }
}
