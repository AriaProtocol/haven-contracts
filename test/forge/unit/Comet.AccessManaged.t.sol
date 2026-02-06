pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {IAccessManager} from "oz/access/manager/IAccessManager.sol";

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
        bytes32 cometHash = 0x074bc775ab1d19244d6a7eb37f9a3a1922378fa6e72ce44768bf8e6396e48bfc;
        _test_recover_RoleRestricted(comet, cometHash);
    }

    function test_recover_RoleRestricted_CometExtendedAssetList() public {
        bytes32 cometExtendedHash = 0xc67a56eb072af7bdb6188c50747888d836345c2cba0efa9bc9b5dad4ba3a2540;
        _test_recover_RoleRestricted(cometExtendedAssetList, cometExtendedHash);
    }

    // withdrawReserves()
    function test_withdrawReserves_RoleRestricted_Comet() public {
        bytes32 cometHash = 0x8a52565cfdb854a0b1379738b060b30f621eadc91a2245d9b2b8789ad3cfb95a;
        _test_withdrawReserves_RoleRestricted(comet, cometHash);
    }

    function test_withdrawReserves_RoleRestricted_CometExtendedAssetList() public {
        bytes32 cometExtendedHash = 0xcd87a02568d242e326d0d1468207dea06228c24781c31f30049ef80ad4f7c9d2;
        _test_withdrawReserves_RoleRestricted(cometExtendedAssetList, cometExtendedHash);
    }

    //============================================= //
    // ============ Internal Functions ============ //
    //============================================= //
    function _test_absorb_RoleRestricted(CometMainInterface cometX) internal {
        address[] memory borrowers = new address[](1);
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

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
        cometX.approveThis(makeAddr("random"), asset, amount);

        vm.startPrank(accessManagerAdmin);
        cometX.approveThis(makeAddr("an address"), asset, amount);
    }

    function _test_buyCollateral_RoleRestricted(CometMainInterface cometX) internal {
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, caller);

        // works for liquidator, but reverts because nothing to buy
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotForSale.selector));
        cometX.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);
    }

    function _test_pause_RoleRestricted(CometMainInterface cometX) internal {
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.pause(true, false, true, false, true);

        // works for pause guardian
        vm.startPrank(pauseGuardian);
        cometX.pause(true, false, true, false, true);
    }

    function _test_recover_RoleRestricted(CometMainInterface cometX, bytes32 hash_) internal {
        address caller = makeAddr("caller");
        address lostAddr = makeAddr("lostAddr");
        address newAddr = makeAddr("newAddr");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.recover(lostAddr, newAddr);

        // works for recoverer, but reverts as operation not scheduled
        vm.startPrank(recovererDelayed);
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometX.recover(lostAddr, newAddr);
    }

    function _test_withdrawReserves_RoleRestricted(CometMainInterface cometX, bytes32 hash_) internal {
        address caller = makeAddr("caller");
        address to = makeAddr("to");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometX.withdrawReserves(to, 1 ether);

        // works for reserve withdrawer, but reverts as not scheduled
        vm.startPrank(withdrawer);
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometX.withdrawReserves(to, 1 ether);
    }
}
