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
                PAUSE_ROLE,
                "PAUSE_ROLE role on pause(...)"
            );
            assertEq(governor.getRoleAdmin(PAUSE_ROLE), 0x0, "default admin for PAUSE_ROLE");
            assertEq(governor.getRoleGuardian(PAUSE_ROLE), 0x0, "no guardian for PAUSE_ROLE");
            assertEq(governor.getRoleGrantDelay(PAUSE_ROLE), 0, "PAUSE_ROLE immediately granted");
            (bool isPauseMember, uint32 pauseExecutionDelay) = governor.hasRole(PAUSE_ROLE, pauseGuardian);
            assertTrue(isPauseMember, "PAUSE_ROLE member");
            assertEq(pauseExecutionDelay, 0, "immediately executed");
        }

        // liquidator
        {
            // absorb & buyCollateral access grouped into same role
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), ABSORB_SELEC),
                LIQUIDATOR_ROLE,
                "LIQUIDATOR_ROLE role on absorb(...)"
            );
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), BUY_COLL_SELEC),
                LIQUIDATOR_ROLE,
                "LIQUIDATOR_ROLE role on buyCollateral(...)"
            );
            assertEq(governor.getRoleAdmin(LIQUIDATOR_ROLE), 0x0, "default admin for LIQUIDATOR_ROLE");
            assertEq(governor.getRoleGuardian(LIQUIDATOR_ROLE), 0x0, "no guardian for LIQUIDATOR_ROLE");
            assertEq(governor.getRoleGrantDelay(LIQUIDATOR_ROLE), 0, "LIQUIDATOR_ROLE immediately granted");
            (bool isLiquidationMember, uint32 liquidationExecutionDelay) = governor.hasRole(LIQUIDATOR_ROLE, liquidator);
            assertTrue(isLiquidationMember, "LIQUIDATOR_ROLE member");
            assertEq(liquidationExecutionDelay, 0, "LIQUIDATOR_ROLE immediately executed");
        }

        // recover
        {
            assertEq(
                governor.getTargetFunctionRole(address(cometExtAsset), RECOVER_SELEC),
                RECOVERER_ROLE,
                "RECOVERER_ROLE role on recover(...)"
            );
            assertEq(governor.getRoleAdmin(RECOVERER_ROLE), 0x0, "default admin for RECOVERER_ROLE");
            assertEq(governor.getRoleGuardian(RECOVERER_ROLE), 0x0, "no guardian for RECOVERER_ROLE");
            assertEq(governor.getRoleGrantDelay(RECOVERER_ROLE), 12 hours, "RECOVERER_ROLE granted after 12h");
            (bool isRecoverMember, uint32 recoverExecutionDelay) = governor.hasRole(RECOVERER_ROLE, recoverer);
            assertTrue(isRecoverMember, "RECOVERER_ROLE member");
            assertEq(recoverExecutionDelay, 1 days, "RECOVERER_ROLE needs 1 days schedule");
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
