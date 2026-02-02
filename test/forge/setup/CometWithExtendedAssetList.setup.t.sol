// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {CometExtAssetList} from "contracts/CometExtAssetList.sol";
import {AssetListFactory} from "contracts/AssetListFactory.sol";
import {CometHarnessExtendedAssetList} from "contracts/test/CometHarnessExtendedAssetList.sol";

import "./0_Common.setup.t.sol";

contract CometWithExtendedAssetList_Setup is Common_Setup {
    CometHarnessExtendedAssetList public cometExtAsset;

    function setUp() public virtual override {
        super.setUp();

        _defineRolesAndGrantDefaultAccess(address(cometExtAsset));
    }

    function test_SetUpState_CometExtendedAssetList() public {
        // pause guardian
        {
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), PAUSE_SELEC),
                PAUSE_GUARDIAN,
                "PAUSE_GUARDIAN role on pause(...)"
            );
            assertEq(governor.getRoleAdmin(PAUSE_GUARDIAN), 0x0, "default admin for PAUSE_GUARDIAN");
            assertEq(governor.getRoleGuardian(PAUSE_GUARDIAN), 0x0, "no guardian for PAUSE_GUARDIAN");
            assertEq(governor.getRoleGrantDelay(PAUSE_GUARDIAN), 0, "PAUSE_GUARDIAN immediately granted");
            (bool isPauseMember, uint32 pauseExecutionDelay) = governor.hasRole(PAUSE_GUARDIAN, pauseGuardian);
            assertTrue(isPauseMember, "PAUSE_GUARDIAN member");
            assertEq(pauseExecutionDelay, 0, "immediately executed");
        }

        // liquidator
        {
            // absorb & buyCollateral access grouped into same role
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), ABSORB_SELEC),
                LIQUIDATOR,
                "LIQUIDATOR role on absorb(...)"
            );
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), BUY_COLL_SELEC),
                LIQUIDATOR,
                "LIQUIDATOR role on buyCollateral(...)"
            );
            assertEq(governor.getRoleAdmin(LIQUIDATOR), 0x0, "default admin for LIQUIDATOR");
            assertEq(governor.getRoleGuardian(LIQUIDATOR), 0x0, "no guardian for LIQUIDATOR");
            assertEq(governor.getRoleGrantDelay(LIQUIDATOR), 0, "LIQUIDATOR immediately granted");
            (bool isLiquidationMember, uint32 liquidationExecutionDelay) = governor.hasRole(LIQUIDATOR, liquidator);
            assertTrue(isLiquidationMember, "LIQUIDATOR member");
            assertEq(liquidationExecutionDelay, 0, "LIQUIDATOR immediately executed");
        }

        assertEq(governor.getTargetAdminDelay(address(cometExtAsset)), 0, "no delay for CometExtAsset");
    }

    function _deployComet() internal override {
        cometExtAsset = new CometHarnessExtendedAssetList(_configureComet());
        cometExtAsset.initializeStorage();
        vm.label(address(cometExtAsset), "CometExtAsset");
    }

    function _deployCometExt() internal override {
        CometConfiguration.ExtConfiguration memory extConfig =
            CometConfiguration.ExtConfiguration({name32: NAME32, symbol32: SYMBOL32});
        extensionDelegate = new CometExtAssetList(extConfig, address(new AssetListFactory()));
    }
}
