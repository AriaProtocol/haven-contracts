pragma solidity ^0.8.15;

import {Fixture_3Sup_3Bor} from "test/forge/setup/Fixture_3Sup_3Bor.t.sol";

contract Comet_transferDebt_Test is Fixture_3Sup_3Bor {
    address public newAddr = makeAddr("new address borrower3");

    function test_transferDebt() public {
        // debt before admin transfer
        uint256 oldAddrBorrow = comet.borrowBalanceOf(borrower3);

        // after debt transfer
        uint256 newAddrBorrow = comet.borrowBalanceOf(newAddr);

        assertEq(newAddrBorrow, oldAddrBorrow, "Debt not transfered");
        assertEq(comet.borrowBalanceOf(borrower3), 0, "OLD addr still has debt");
    }
}
