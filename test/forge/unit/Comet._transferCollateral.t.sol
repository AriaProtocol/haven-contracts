pragma solidity ^0.8.15;

import {CometMainInterface} from "contracts/CometMainInterface.sol";
import {CometExtInterface} from "contracts/CometExtInterface.sol";
import {CometStorage} from "contracts/CometStorage.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

/// @dev Internal _transferCollateral(...)
contract Comet__transferCollateral_Test is Fixture_3Sup_3Bor, CometStorage {
    address public newAddr = makeAddr("new address borrower3");

    function setUp() public override {
        super.setUp();

        _loadFixture(comet);
        _loadFixture(cometExtendedAssetList);
    }

    function test_transferCollateral_CometX() internal {
        _test_transferCollateral(address(comet), " - Comet.sol");
        _test_transferCollateral(address(cometExtendedAssetList), " - CometExtendedWithAssetList.sol");
    }

    function _test_transferCollateral(address cometX, string memory type_) internal {
        UserCollateral memory lostWeth;
        UserCollateral memory lostWbtc;
        (lostWeth.balance, lostWeth._reserved) = _userCollateral(cometX, borrower3, address(weth));
        (lostWbtc.balance, lostWbtc._reserved) = _userCollateral(cometX, borrower3, address(wbtc));

        bytes4 selector = bytes4(keccak256("exposed_transferCollateral(address,address)"));
        cometX.call(abi.encodeWithSelector(selector, borrower3, newAddr));

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
