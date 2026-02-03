pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {IAccessManager} from "oz/access/manager/IAccessManager.sol";

import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {CometWithExtendedAssetList_Setup} from "test/forge/setup/CometWithExtendedAssetList.setup.t.sol";

/// @dev Test `AccessManaged` managed config in Comet, on function with `restricted` modifier
contract CometWExtAssetList_AccessManaged_Test is CometWithExtendedAssetList_Setup {
    function test_absorb_RoleRestricted() public {
        address[] memory borrowers = new address[](1);
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.absorb(absorber, borrowers);

        // works for liquidator, but reverts because nothing to absorb
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotLiquidatable.selector));
        cometExtAsset.absorb(absorber, borrowers);
    }

    function test_approveThis_RoleRestricted() public {
        address asset = address(weth);
        uint amount = 1 ether;
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.approveThis(makeAddr("random"), asset, amount);

        vm.startPrank(accessManagerAdmin);
        cometExtAsset.approveThis(makeAddr("an address"), asset, amount);
    }

    function test_buyCollateral_RoleRestricted() public {
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, caller);

        // works for liquidator, but reverts because nothing to buy
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotForSale.selector));
        cometExtAsset.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);
    }

    function test_pause_RoleRestricted() public {
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.pause(true, false, true, false, true);

        // works for pause guardian
        vm.startPrank(pauseGuardian);
        cometExtAsset.pause(true, false, true, false, true);
    }

    function test_recover_RoleRestricted() public {
        address caller = makeAddr("caller");
        address lostAddr = makeAddr("lostAddr");
        address newAddr = makeAddr("newAddr");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.recover(lostAddr, newAddr);

        // works for recoverer, but reverts because nothing to recover
        vm.startPrank(recoverer);
        bytes32 hash_ = 0x57a3b28795615e7c4399358d033f3e597d663f5e2ae95c788c45e24286d991a5;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometExtAsset.recover(lostAddr, newAddr);
    }

    function test_withdrawReserves_RoleRestricted() public {
        address caller = makeAddr("caller");
        address to = makeAddr("to");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        cometExtAsset.withdrawReserves(to, 1 ether);

        // works for reserve withdrawer, but reverts as not scheduled
        vm.startPrank(withdrawer);
        bytes32 hash_ = 0x179e26237c7ee564c67c9bbae1f4d25fabc9d653b123dd815bbfa4fed6b3c3c8;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        cometExtAsset.withdrawReserves(to, 1 ether);
    }
}
