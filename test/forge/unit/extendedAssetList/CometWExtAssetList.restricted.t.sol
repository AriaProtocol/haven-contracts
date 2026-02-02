pragma solidity ^0.8.15;

import {IAccessManaged} from "oz/access/manager/IAccessManaged.sol";

import {CometMainInterface} from "contracts/CometMainInterface.sol";

import {CometWithExtendedAssetList_Setup} from "test/forge/setup/CometWithExtendedAssetList.setup.t.sol";

contract CometWExtAssetList_restricted_Test is CometWithExtendedAssetList_Setup {
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
}
