pragma solidity ^0.8.15;

import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

contract Comet_transferDebt_Test is Fixture_3Sup_3Bor {
    address public newAddr = makeAddr("new address borrower3");

    function test_transferDebt() public {
        // debt before admin transfer
        uint256 lostAddrBorrow = comet.borrowBalanceOf(borrower3);
        (
            int104 lostPrincipal,
            uint64 lostBaseTrackingIndex,
            uint64 lostBaseTrackingAccrued,
            uint16 lostAssetsIn,
            uint8 lost_reserved
        ) = comet.userBasic(borrower3);

        comet.exposed_transferDebt(borrower3, newAddr);

        // after debt transfer
        assertEq(comet.borrowBalanceOf(newAddr), lostAddrBorrow, "Debt not transfered");
        assertEq(comet.borrowBalanceOf(borrower3), 0, "LOST addr still has debt");
        // UserBasic struct update checks
        {
            // newAddr has borrower3 data
            {
                (
                    int104 newPrincipal,
                    uint64 newBaseTrackingIndex,
                    uint64 newBaseTrackingAccrued,
                    uint16 newAssetsIn,
                    uint8 new_reserved
                ) = comet.userBasic(newAddr);
                assertEq(newPrincipal, lostPrincipal, "NEW userBasic.principal");
                assertEq(newBaseTrackingIndex, lostBaseTrackingIndex, "NEW userBasic.baseTrackingIndex");
                assertEq(newBaseTrackingAccrued, lostBaseTrackingAccrued, "NEW userBasic.baseTrackingAccrued");
                assertEq(newAssetsIn, lostAssetsIn, "NEW userBasic.assetsIn");
                assertEq(new_reserved, lost_reserved, "NEW userBasic._reserved");
            }

            // lost is completely reseted
            {
                (lostPrincipal, lostBaseTrackingIndex, lostBaseTrackingAccrued, lostAssetsIn, lost_reserved) =
                    comet.userBasic(borrower3);
                assertEq(lostPrincipal, 0, "LOST userBasic.principal");
                assertEq(lostBaseTrackingIndex, 0, "LOST userBasic.baseTrackingIndex");
                assertEq(lostBaseTrackingAccrued, 0, "LOST userBasic.baseTrackingAccrued");
                assertEq(lostAssetsIn, 0, "LOST userBasic.assetsIn");
                assertEq(lost_reserved, 0, "LOST userBasic._reserved");
            }
        }
    }
}
