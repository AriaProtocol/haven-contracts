// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "test/forge/setup/0_Common.setup.t.sol";

/// @dev solely testing setup state
contract Comet_setup_Test is Common_Setup {
    function test_SetUpState_Governor_Comet() public {
        __checkOnCometInstance(address(comet));
    }

    function test_SetUpState_Governor_CometExtendedAssetList() public {
        __checkOnCometInstance(address(cometExtendedAssetList));
    }

    function test_SetUpState_Governor() public {
        // pause role
        {
            assertEq(governor.getRoleAdmin(PAUSE_ROLE), 0x0, "default admin for PAUSE_ROLE");
            assertEq(governor.getRoleGuardian(PAUSE_ROLE), PAUSE_GUARDIAN, "PAUSE_GUARDIAN for PAUSE_ROLE");
            assertEq(governor.getRoleGrantDelay(PAUSE_ROLE), 0, "PAUSE_ROLE immediately granted");
            (bool isPauseMember, uint32 pauseExecutionDelay) = governor.hasRole(PAUSE_ROLE, pauseGuardian);
            assertTrue(isPauseMember, "PAUSE_ROLE member");
            assertEq(pauseExecutionDelay, PAUSE_DELAY, "immediately executed");
            // pause guardian role
            assertEq(governor.getRoleGrantDelay(PAUSE_GUARDIAN), 0, "PAUSE_GUARDIAN immediately granted");
            (bool isPauseGuardianMember, uint32 pauseGuardianExecutionDelay) =
                governor.hasRole(PAUSE_GUARDIAN, pauseGuardian);
            assertTrue(isPauseGuardianMember, "PAUSE_GUARDIAN member");
            assertEq(pauseGuardianExecutionDelay, PAUSE_DELAY, "PAUSE_GUARDIAN immediately executed");
        }

        // liquidator
        {
            assertEq(governor.getRoleAdmin(LIQUIDATOR_ROLE), 0x0, "default admin for LIQUIDATOR_ROLE");
            assertEq(governor.getRoleGuardian(LIQUIDATOR_ROLE), 0x0, "no guardian for LIQUIDATOR_ROLE");
            assertEq(governor.getRoleGrantDelay(LIQUIDATOR_ROLE), 0, "LIQUIDATOR_ROLE immediately granted");
            (bool isLiquidationMember, uint32 liquidationExecutionDelay) = governor.hasRole(LIQUIDATOR_ROLE, liquidator);
            assertTrue(isLiquidationMember, "LIQUIDATOR_ROLE member");
            assertEq(liquidationExecutionDelay, LIQUIDATOR_DELAY, "LIQUIDATOR_ROLE immediately executed");
        }

        // recover
        {
            assertEq(governor.getRoleAdmin(RECOVERER_ROLE), 0x0, "default admin for RECOVERER_ROLE");
            assertEq(governor.getRoleGuardian(RECOVERER_ROLE), 0x0, "no guardian for RECOVERER_ROLE");
            assertEq(
                governor.getRoleGrantDelay(RECOVERER_ROLE), RECOVERER_GRANT_DELAY, "RECOVERER_ROLE granted after 12h"
            );
            // unauthorized recoverer (not granted role)
            (bool isRecoverMember, uint32 recoverExecutionDelay) = governor.hasRole(RECOVERER_ROLE, recoverer);
            assertFalse(isRecoverMember, "recoverer is NOT a RECOVERER_ROLE member");
            assertEq(recoverExecutionDelay, RECOVER_DELAY, "RECOVERER_ROLE always has the same delay");
            // delayed recoverer
            (isRecoverMember, recoverExecutionDelay) = governor.hasRole(RECOVERER_ROLE, recovererDelayed);
            assertTrue(isRecoverMember, "RECOVERER_ROLE member");
            assertEq(recoverExecutionDelay, RECOVER_DELAY, "RECOVERER_ROLE needs 1 days schedule");
        }

        // withdrawer
        {
            assertEq(governor.getRoleAdmin(WITHDRAWER_ROLE), 0x0, "default admin for WITHDRAWER_ROLE");
            assertEq(governor.getRoleGuardian(WITHDRAWER_ROLE), 0x0, "no guardian for WITHDRAWER_ROLE");
            assertEq(
                governor.getRoleGrantDelay(WITHDRAWER_ROLE),
                WITHDRAWER_GRANT_DELAY,
                "WITHDRAWER_ROLE granted after 6 days"
            );
            (bool isWithdrawMember, uint32 withdrawExecutionDelay) = governor.hasRole(WITHDRAWER_ROLE, withdrawer);
            assertTrue(isWithdrawMember, "WITHDRAWER_ROLE member");
            assertEq(withdrawExecutionDelay, WITHDRAWER_DELAY, "WITHDRAWER_ROLE needs 6 days schedule");
        }
    }

    function __checkOnCometInstance(address comet) private {
        // pause
        assertEq(governor.getTargetFunctionRole(comet, PAUSE_SELEC), PAUSE_ROLE, "PAUSE_ROLE role on pause(...)");

        // liquidator: `absorb` & `buyCollateral` accesses grouped into same role
        assertEq(
            governor.getTargetFunctionRole(comet, ABSORB_SELEC), LIQUIDATOR_ROLE, "LIQUIDATOR_ROLE role on absorb(...)"
        );
        assertEq(
            governor.getTargetFunctionRole(comet, BUY_COLL_SELEC),
            LIQUIDATOR_ROLE,
            "LIQUIDATOR_ROLE role on buyCollateral(...)"
        );

        // recover
        assertEq(
            governor.getTargetFunctionRole(comet, RECOVER_SELEC), RECOVERER_ROLE, "RECOVERER_ROLE role on recover(...)"
        );

        // withdrawer
        assertEq(
            governor.getTargetFunctionRole(comet, WITHDRAW_SELECT),
            WITHDRAWER_ROLE,
            "WITHDRAWER_ROLE role on withdraw(...)"
        );

        assertEq(governor.getTargetAdminDelay(comet), 0, "no delay for comet");
    }
}
