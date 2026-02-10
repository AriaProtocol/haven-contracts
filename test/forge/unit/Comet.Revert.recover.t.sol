pragma solidity ^0.8.15;

import {CometMainInterface} from "contracts/CometMainInterface.sol";
import {CometStorage} from "contracts/CometStorage.sol";
import {FaucetToken} from "contracts/test/FaucetToken.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

contract Comet_Revert_recover_Test is Fixture_3Sup_3Bor, CometStorage {
    address public collateral_er = address(0x432038512);

    function setUp() public override {
        super.setUp();

        _loadFixture(comet);
        _loadFixture(cometExtendedAssetList);

        // address w/ collateral but no borrowings
        {
            vm.label(collateral_er, "Collateral.ER");

            vm.startPrank(collateral_er);
            _supplyCollateral(comet, weth, 100e18, collateral_er);
            _supplyCollateral(cometExtendedAssetList, baseToken, 100e6, collateral_er);
            // ensure _reserved is used, when asset amount >= 17
            for (uint8 i = 0; i < extraTokens.length; ++i) {
                _supplyCollateral(cometExtendedAssetList, extraTokens[i], 100e18, collateral_er);
            }
            vm.stopPrank();
        }
    }

    function test_RevertOn_SelfTransfer_recover() public {
        _test_RevertOn_SelfTransfer_recover(comet);
        _test_RevertOn_SelfTransfer_recover(cometExtendedAssetList);
    }

    function test_RevertOn_ZeroAddress_recover() public {
        _test_RevertOn_ZeroAddress_recover(comet);
        _test_RevertOn_ZeroAddress_recover(cometExtendedAssetList);
    }

    function test_RevertWhen_NewAccountIsNotEmpty_AlreadyABorrower() public {
        _test_RevertWhen_NewAccountIsNotEmpty_AlreadyABorrower(comet);
        _test_RevertWhen_NewAccountIsNotEmpty_AlreadyABorrower(cometExtendedAssetList);
    }

    function test_RevertWhen_NewAccountIsNotEmpty_AlreadyASupplier() public {
        _test_RevertWhen_NewAccountIsNotEmpty_AlreadyASupplier(comet);
        _test_RevertWhen_NewAccountIsNotEmpty_AlreadyASupplier(cometExtendedAssetList);
    }

    function test_RevertWhen_NewAccountIsNotEmpty_HasCollateralWithoutBorrowings() public {
        _test_RevertWhen_NewAccountIsNotEmpty_HasCollateralWithoutBorrowings(comet);
        _test_RevertWhen_NewAccountIsNotEmpty_HasCollateralWithoutBorrowings(cometExtendedAssetList);
    }

    //============================================= //
    // ============ Internal Functions ============ //
    //============================================= //
    function _test_RevertOn_SelfTransfer_recover(CometMainInterface cometX) internal {
        vm.startPrank(recoverer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NoSelfTransfer.selector));
        cometX.recover(borrower3, borrower3);
    }

    function _test_RevertOn_ZeroAddress_recover(CometMainInterface cometX) internal {
        vm.startPrank(recoverer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.ZeroAddress.selector));
        cometX.recover(borrower3, address(0));
    }

    function _test_RevertWhen_NewAccountIsNotEmpty_AlreadyABorrower(CometMainInterface cometX) internal {
        vm.startPrank(recoverer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.AccountNotEmpty.selector));
        cometX.recover(borrower3, borrower1);
    }

    function _test_RevertWhen_NewAccountIsNotEmpty_AlreadyASupplier(CometMainInterface cometX) internal {
        vm.startPrank(recoverer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.AccountNotEmpty.selector));
        cometX.recover(borrower3, supplier3);
    }

    function _test_RevertWhen_NewAccountIsNotEmpty_HasCollateralWithoutBorrowings(CometMainInterface cometX) internal {
        vm.startPrank(recoverer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.AccountNotEmpty.selector));
        cometX.recover(borrower3, collateral_er);
    }

    // Utils
    function _supplyCollateral(CometMainInterface cometX, FaucetToken token, uint256 amount, address to) internal {
        token.allocateTo(to, amount);
        token.approve(address(cometX), type(uint256).max);
        cometX.supply(address(token), amount);
    }
}
