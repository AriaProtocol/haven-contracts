pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {IAccessManager} from "oz/access/manager/IAccessManager.sol";
import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {Common_Setup} from "test/forge/setup/0_Common.setup.t.sol";

/// @dev Test `AccessManaged` managed config in Comet, on function with `restricted` modifier
contract Comet_AccessManaged_Test is Common_Setup {
    function test_absorb_RoleRestricted() public {
        address[] memory borrowers = new address[](1);
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.absorb(absorber, borrowers);

        // works for liquidator, but reverts because nothing to absorb
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotLiquidatable.selector));
        comet.absorb(absorber, borrowers);
    }

    function test_approveThis_RoleRestricted() public {
        address asset = address(weth);
        uint amount = 1 ether;
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.approveThis(makeAddr("random"), asset, amount);

        vm.startPrank(accessManagerAdmin);
        comet.approveThis(makeAddr("an address"), asset, amount);
    }

    function test_buyCollateral_RoleRestricted() public {
        address absorber = makeAddr("absorber");
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, caller);

        // works for liquidator, but reverts because nothing to buy
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(CometMainInterface.NotForSale.selector));
        comet.buyCollateral(address(weth), 0.5 ether, 1500 * 1e6, absorber);
    }

    function test_pause_RoleRestricted() public {
        address caller = makeAddr("caller");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.pause(true, false, true, false, true);

        // works for pause guardian
        vm.startPrank(pauseGuardian);
        comet.pause(true, false, true, false, true);
    }

    function test_recover_RoleRestricted() public {
        address caller = makeAddr("caller");
        address lostAddr = makeAddr("lostAddr");
        address newAddr = makeAddr("newAddr");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.recover(lostAddr, newAddr);

        // works for recoverer, but reverts as operation not scheduled
        vm.startPrank(recoverer);
        bytes32 hash_ = 0x0c2e5ccc6153de54ab6d3605e33fef2a348e4c72cd2d22bb257383256e10aeae;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        comet.recover(lostAddr, newAddr);
    }

    function test_withdrawReserves_RoleRestricted() public {
        address caller = makeAddr("caller");
        address to = makeAddr("to");

        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, caller));
        comet.withdrawReserves(to, 1 ether);

        // works for reserve withdrawer, but reverts as not scheduled
        vm.startPrank(withdrawer);
        bytes32 hash_ = 0x8a52565cfdb854a0b1379738b060b30f621eadc91a2245d9b2b8789ad3cfb95a;
        vm.expectRevert(abi.encodeWithSelector(IAccessManager.AccessManagerNotScheduled.selector, hash_));
        comet.withdrawReserves(to, 1 ether);
    }
}
