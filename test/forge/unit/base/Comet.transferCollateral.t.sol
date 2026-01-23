pragma solidity ^0.8.15;

import {CometExtInterface} from "contracts/CometExtInterface.sol";

import {Comet_Setup} from "test/forge/setup/Comet.setup.t.sol";
import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

contract Comet_transferCollateral_Test is Comet_Setup, Fixture_3Sup_3Bor {
    address public newAddr = makeAddr("new address borrower3");

    CometExtInterface public cometExt;

    function setUp() public override {
        super.setUp();

        _loadFixture(comet, baseToken, weth, wbtc);

        cometExt = CometExtInterface(address(comet));
    }

    function test_transferCollateral() public {
        // collateral before admin transfer; userCollateral(...) returns _reserved on top => only use in CometWithExtendedAssetList
        uint128 lostWethCollBalance = cometExt.collateralBalanceOf(borrower3, address(weth));
        uint128 lostWbtcCollBalance = cometExt.collateralBalanceOf(borrower3, address(wbtc));

        comet.exposed_transferCollateral(borrower3, newAddr);

        // newAddr has borrower3 collateral
        {
            assertEq(
                cometExt.collateralBalanceOf(newAddr, address(weth)),
                lostWethCollBalance,
                "NewAddr DOES NOT have WETH as collateral"
            );
            assertEq(
                cometExt.collateralBalanceOf(newAddr, address(wbtc)),
                lostWbtcCollBalance,
                "NewAddr DOES NOT have WBTC as collateral"
            );
        }

        // lost address does not have any collateral
        {
            assertEq(cometExt.collateralBalanceOf(borrower3, address(weth)), 0, "Borrower3 WETH collateral NOT cleaned");
            assertEq(cometExt.collateralBalanceOf(borrower3, address(wbtc)), 0, "Borrower3 WBTC collateral NOT cleaned");
        }
    }
}
