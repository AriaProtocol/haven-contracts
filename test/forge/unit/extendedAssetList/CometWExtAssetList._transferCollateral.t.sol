pragma solidity ^0.8.15;

import {CometExtInterface} from "contracts/CometExtInterface.sol";

import {CometWithExtendedAssetList_Setup} from "test/forge/setup/CometWithExtendedAssetList.setup.t.sol";
import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

/// @dev Internal _transferCollateral(...)
contract CometWExtAssetList__transferCollateral_Test is CometWithExtendedAssetList_Setup, Fixture_3Sup_3Bor {
    address public newAddr = makeAddr("new address borrower3");

    CometExtInterface public cometExt;

    function setUp() public override {
        super.setUp();

        _loadFixture(cometExtAsset, baseToken, weth, wbtc);

        cometExt = CometExtInterface(address(cometExtAsset));
    }

    function test_transferCollateral() public {
        (uint128 lostWethCollBalance, uint128 lostWeth_reserved) = cometExt.userCollateral(borrower3, address(weth));
        (uint128 lostWbtcCollBalance, uint128 lostWbtc_reserved) = cometExt.userCollateral(borrower3, address(wbtc));

        cometExtAsset.exposed_transferCollateral(borrower3, newAddr);

        // newAddr has borrower3 collateral data
        {
            // WETH
            {
                (uint128 newWethCollBalance, uint128 newWeth_reserved) = cometExt.userCollateral(newAddr, address(weth));
                assertEq(newWethCollBalance, lostWethCollBalance, "NewAddr DOES NOT have WETH as collateral");
                assertEq(newWeth_reserved, lostWeth_reserved, "NewAddr DOES NOT have WETH reserved");
            }
            // WBTC
            {
                (uint128 newWbtcCollBalance, uint128 newWbtc_reserved) = cometExt.userCollateral(newAddr, address(wbtc));
                assertEq(newWbtcCollBalance, lostWbtcCollBalance, "NewAddr DOES NOT have WBTC as collateral");
                assertEq(newWbtc_reserved, lostWbtc_reserved, "NewAddr DOES NOT have WBTC reserved");
            }
        }

        // lost address collateral data reseted
        {
            // WETH
            {
                (uint128 lostWethCollBalance, uint128 lostWeth_reserved) =
                    cometExt.userCollateral(borrower3, address(weth));
                assertEq(lostWethCollBalance, 0, "Borrower3 WETH collateral NOT cleaned");
                assertEq(lostWeth_reserved, 0, "Borrower3 WETH reserved NOT cleaned");
            }
            // WBTC
            {
                (uint128 lostWbtcCollBalance, uint128 lostWbtc_reserved) =
                    cometExt.userCollateral(borrower3, address(wbtc));
                assertEq(lostWbtcCollBalance, 0, "Borrower3 WBTC collateral NOT cleaned");
                assertEq(lostWbtc_reserved, 0, "Borrower3 WBTC reserved NOT cleaned");
            }
        }
    }
}
