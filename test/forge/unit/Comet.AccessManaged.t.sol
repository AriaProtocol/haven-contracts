pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {IAccessManagerCustom} from "aria/access/interfaces/IAccessManagerCustom.sol";

import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {Common_Setup} from "test/forge/setup/0_Common.setup.t.sol";

/// @dev Test `AccessManaged` managed config in Comet, on function with `restricted` modifier
contract Comet_AccessManaged_Test is Common_Setup {
    // absorb()
    function test_absorb_RoleRestricted_Comet() public {
        _test_absorb_RoleRestricted(comet);
    }

    function test_absorb_RoleRestricted_CometExtendedAssetList() public {
        _test_absorb_RoleRestricted(cometExtendedAssetList);
    }

    // approveThis()
    function test_approveThis_RoleRestricted_Comet() public {
        _test_approveThis_RoleRestricted(comet);
    }

    function test_approveThis_RoleRestricted_CometExtendedAssetList() public {
        _test_approveThis_RoleRestricted(cometExtendedAssetList);
    }

    // buyCollateral()
    function test_buyCollateral_RoleRestricted_Comet() public {
        _test_buyCollateral_RoleRestricted(comet);
    }

    function test_buyCollateral_RoleRestricted_CometExtendedAssetList() public {
        _test_buyCollateral_RoleRestricted(cometExtendedAssetList);
    }

    // pause()
    function test_pause_RoleRestricted_Comet() public {
        _test_pause_RoleRestricted(comet);
    }

    function test_pause_RoleRestricted_CometExtendedAssetList() public {
        _test_pause_RoleRestricted(cometExtendedAssetList);
    }

    // recover()
    function test_recover_RoleRestricted_Comet() public {
        _test_recover_RoleRestricted(comet);
    }

    function test_recover_RoleRestricted_CometExtendedAssetList() public {
        _test_recover_RoleRestricted(cometExtendedAssetList);
    }

    // withdrawReserves()
    function test_withdrawReserves_RoleRestricted_Comet() public {
        _test_withdrawReserves_RoleRestricted(comet);
    }

    function test_withdrawReserves_RoleRestricted_CometExtendedAssetList() public {
        _test_withdrawReserves_RoleRestricted(cometExtendedAssetList);
    }

    // ------------------------------------------ //
    // -------------- Revert Cases -------------- //
    // ------------------------------------------ //
    /// @dev Revert because `recoverer` address does not hold the RECOVERER_ROLE (execution delay is per-role)
    function testRevert_schedule_Unauthorized() public {
        vm.startPrank(recoverer);

        address oldAddr = makeAddr("oldAddr");
        address newAddr = makeAddr("newAddr");
        bytes memory data = abi.encodeWithSelector(RECOVER_SELEC, oldAddr, newAddr);

        // comet
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManagerCustom.AccessManagerUnauthorizedCall.selector, recoverer, address(comet), RECOVER_SELEC
            )
        );
        governor.schedule(address(comet), data, 0);

        // comet extended asset list
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManagerCustom.AccessManagerUnauthorizedCall.selector,
                recoverer,
                address(cometExtendedAssetList),
                RECOVER_SELEC
            )
        );
        governor.schedule(address(cometExtendedAssetList), data, 0);
    }

    //============================================= //
    // ============ Internal Functions ============ //
    //============================================= //
    function _test_absorb_RoleRestricted(CometMainInterface cometX) internal {
        address[] memory borrowers = new address[](1);
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        // schedule
        vm.startPrank(liquidator);
        {
            bytes memory data = abi.encodeWithSelector(ABSORB_SELEC, absorber, borrowers);
            governor.schedule(address(cometX), data, 0);

            // setback required for liquidator delay
            skip(LIQUIDATOR_DELAY);
        }

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.absorb(absorber, borrowers);

        // works for liquidator, but reverts because nothing to absorb
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotLiquidatable.selector));
        cometX.absorb(absorber, borrowers);
    }

    function _test_approveThis_RoleRestricted(CometMainInterface cometX) internal {
        address asset = address(weth);
        uint amount = 1 ether;
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.approveThis(makeAddr("an address"), asset, amount);
    }

    function _test_buyCollateral_RoleRestricted(CometMainInterface cometX) internal {
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        // schedule
        vm.startPrank(liquidator);
        {
            bytes memory data = abi.encodeWithSelector(BUY_COLL_SELEC, address(weth), 0.5 ether, 1500 * 1e6, absorber);
            governor.schedule(address(cometX), data, 0);

            // setback required for liquidator delay
            skip(LIQUIDATOR_DELAY);
        }

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);

        // works for liquidator, but reverts because nothing to buy
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotForSale.selector));
        cometX.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);
    }

    function _test_pause_RoleRestricted(CometMainInterface cometX) internal {
        address caller = makeAddr("caller");

        // schedule
        vm.startPrank(pauseGuardian);
        {
            bytes memory data = abi.encodeWithSelector(PAUSE_SELEC, true, false, true, false, true);
            governor.schedule(address(cometX), data, 0);

            // setback required for pause delay
            skip(PAUSE_DELAY);
        }

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.pause(true, false, true, false, true);

        // works for pause guardian
        vm.startPrank(pauseGuardian);
        cometX.pause(true, false, true, false, true);
    }

    function _test_recover_RoleRestricted(CometMainInterface cometX) internal {
        address caller = makeAddr("caller");
        address lostAddr = makeAddr("lostAddr");
        address newAddr = makeAddr("newAddr");

        // schedule
        vm.startPrank(recovererDelayed);
        {
            bytes memory data = abi.encodeWithSelector(RECOVER_SELEC, lostAddr, newAddr);
            governor.schedule(address(cometX), data, 0);

            // setback required for recoverer delay
            skip(RECOVER_DELAY);
        }

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.recover(lostAddr, newAddr);

        // works for recoverer
        vm.startPrank(recovererDelayed);
        cometX.recover(lostAddr, newAddr);
    }

    function _test_withdrawReserves_RoleRestricted(CometMainInterface cometX) internal {
        address caller = makeAddr("caller");
        address to = makeAddr("to");

        // schedule
        vm.startPrank(withdrawer);
        {
            bytes memory data = abi.encodeWithSelector(WITHDRAW_SELECT, to, 1 ether);
            governor.schedule(address(cometX), data, 0);

            // setback required for withdrawer delay
            skip(WITHDRAWER_DELAY);
        }

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.withdrawReserves(to, 1 ether);

        // works for reserve withdrawer, but reverts as not scheduled
        vm.startPrank(withdrawer);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.InsufficientReserves.selector));
        cometX.withdrawReserves(to, 1 ether);
    }
}
