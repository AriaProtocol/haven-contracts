// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {CometHarness} from "contracts/test/CometHarness.sol";

import "./0_Common.setup.t.sol";

contract Comet_Setup is Common_Setup {
    CometHarness public comet;

    function setUp() public virtual override {
        super.setUp();

        _defineRolesAndGrantDefaultAccess(address(comet));
    }

    function test_SetUpState_Comet() public {
        // pause guardian
        {
            assertEq(
                governor.getTargetFunctionRole(address(comet), PAUSE_SELEC),
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
                governor.getTargetFunctionRole(address(comet), ABSORB_SELEC),
                LIQUIDATOR,
                "LIQUIDATOR role on absorb(...)"
            );
            assertEq(
                governor.getTargetFunctionRole(address(comet), BUY_COLL_SELEC),
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

        // recover
        {
            assertEq(
                governor.getTargetFunctionRole(address(comet), RECOVER_SELEC),
                RECOVERER,
                "RECOVERER role on recover(...)"
            );
            assertEq(governor.getRoleAdmin(RECOVERER), 0x0, "default admin for RECOVERER");
            assertEq(governor.getRoleGuardian(RECOVERER), 0x0, "no guardian for RECOVERER");
            assertEq(governor.getRoleGrantDelay(RECOVERER), 12 hours, "RECOVERER granted after 12h");
            (bool isRecoverMember, uint32 recoverExecutionDelay) = governor.hasRole(RECOVERER, recoverer);
            assertTrue(isRecoverMember, "RECOVERER member");
            assertEq(recoverExecutionDelay, 1 days, "RECOVERER needs 1 days schedule");
        }

        assertEq(governor.getTargetAdminDelay(address(comet)), 0, "no delay for comet");
    }

    function _deployComet() internal override {
        comet = new CometHarness(_configureComet());
        comet.initializeStorage();
        vm.label(address(comet), "Comet");
    }

    function _deployCometExt() internal override {
        CometConfiguration.ExtConfiguration memory extConfig =
            CometConfiguration.ExtConfiguration({name32: NAME32, symbol32: SYMBOL32});
        extensionDelegate = new CometExt(extConfig);
    }
}
