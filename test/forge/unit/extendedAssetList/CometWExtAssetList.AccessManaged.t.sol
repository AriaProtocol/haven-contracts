pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {IAccessManager} from "oz/access/manager/IAccessManager.sol";

import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {Common_Setup} from "test/forge/setup/0_Common.setup.t.sol";

/// @dev Test `AccessManaged` managed config in Comet, on function with `restricted` modifier
contract CometWExtAssetList_AccessManaged_Test is Common_Setup {
    function test_absorb_RoleRestricted() public {
        address[] memory borrowers = new address[](1);
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.absorb(absorber, borrowers);

        // works for liquidator, but reverts because nothing to absorb
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotLiquidatable.selector));
        cometExtendedAssetList.absorb(absorber, borrowers);
    }

    function test_approveThis_RoleRestricted() public {
        address asset = address(weth);
        uint amount = 1 ether;
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.approveThis(makeAddr("random"), asset, amount);

        vm.startPrank(accessManagerAdmin);
        cometExtendedAssetList.approveThis(makeAddr("an address"), asset, amount);
    }

    function test_buyCollateral_RoleRestricted() public {
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, caller);

        // works for liquidator, but reverts because nothing to buy
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotForSale.selector));
        cometExtendedAssetList.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);
    }

    function test_pause_RoleRestricted() public {
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.pause(true, false, true, false, true);

        // works for pause guardian
        vm.startPrank(pauseGuardian);
        cometExtendedAssetList.pause(true, false, true, false, true);
    }

    function test_recover_RoleRestricted() public {
        address caller = makeAddr("caller");
        address lostAddr = makeAddr("lostAddr");
        address newAddr = makeAddr("newAddr");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.recover(lostAddr, newAddr);

        // works for recoverer, but reverts because nothing to recover
        vm.startPrank(recoverer);
        bytes32 hash_ = 0x9d7a8ff24c3ddc092fb8162e75d9c0e600771a65cd01a6906553871e20e09f3b;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometExtendedAssetList.recover(lostAddr, newAddr);
    }

    function test_withdrawReserves_RoleRestricted() public {
        address caller = makeAddr("caller");
        address to = makeAddr("to");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtendedAssetList.withdrawReserves(to, 1 ether);

        // works for reserve withdrawer, but reverts as not scheduled
        vm.startPrank(withdrawer);
        bytes32 hash_ = 0xcd87a02568d242e326d0d1468207dea06228c24781c31f30049ef80ad4f7c9d2;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometExtendedAssetList.withdrawReserves(to, 1 ether);
    }
}
