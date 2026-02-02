pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";
import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {Comet_Setup} from "test/forge/setup/Comet.setup.t.sol";

contract Comet_restricted_Test is Comet_Setup {
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
}
