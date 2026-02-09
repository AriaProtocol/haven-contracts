pragma solidity ^0.8.15;

import {CometMainInterface} from "contracts/CometMainInterface.sol";
import {CometStorage} from "contracts/CometStorage.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/fixtures/Fixture_3Sup_3Bor.t.sol";

/// @dev Internal _transferDebtOrSupply(...)
contract Comet__transferDebt_Test is Fixture_3Sup_3Bor, CometStorage {
    address public newAddr = makeAddr("new address borrower3");

    function setUp() public override {
        super.setUp();

        _loadFixture(comet);
        _loadFixture(cometExtendedAssetList);
    }

    function test_transferDebtOrSupply() public {
        _test_transferDebtOrSupply(comet, " - Comet.sol");
        _test_transferDebtOrSupply(cometExtendedAssetList, " - CometExtendedWithAssetList.sol");
    }

    function _test_transferDebtOrSupply(CometMainInterface cometX, string memory type_) internal {
        // debt before admin transfer
        UserBasic memory lostUserBasic;
        uint256 lostAddrBorrow = cometX.borrowBalanceOf(borrower3);
        lostUserBasic = _userBasic(cometX, borrower3);

        bytes4 selector = bytes4(keccak256("exposed_transferDebtOrSupply(address,address)"));
        address(cometX).call(abi.encodeWithSelector(selector, borrower3, newAddr));

        // after debt transfer
        assertEq(cometX.borrowBalanceOf(newAddr), lostAddrBorrow, _concat("Debt not transfered", type_));
        assertEq(cometX.borrowBalanceOf(borrower3), 0, _concat("LOST addr still has debt", type_));
        // UserBasic struct update checks
        {
            // newAddr has borrower3 data
            {
                UserBasic memory newUserBasic;
                newUserBasic = _userBasic(cometX, newAddr);
                assertEq(newUserBasic.principal, lostUserBasic.principal, _concat("NEW userBasic.principal", type_));
                assertEq(
                    newUserBasic.baseTrackingIndex,
                    lostUserBasic.baseTrackingIndex,
                    _concat("NEW userBasic.baseTrackingIndex", type_)
                );
                assertEq(
                    newUserBasic.baseTrackingAccrued,
                    lostUserBasic.baseTrackingAccrued,
                    _concat("NEW userBasic.baseTrackingAccrued", type_)
                );
                assertEq(newUserBasic.assetsIn, lostUserBasic.assetsIn, _concat("NEW userBasic.assetsIn", type_));
                assertEq(newUserBasic._reserved, lostUserBasic._reserved, _concat("NEW userBasic._reserved", type_));
            }

            // lost is completely reseted
            {
                lostUserBasic = _userBasic(cometX, borrower3);
                assertEq(lostUserBasic.principal, 0, _concat("LOST userBasic.principal", type_));
                assertEq(lostUserBasic.baseTrackingIndex, 0, _concat("LOST userBasic.baseTrackingIndex", type_));
                assertEq(lostUserBasic.baseTrackingAccrued, 0, _concat("LOST userBasic.baseTrackingAccrued", type_));
                assertEq(lostUserBasic.assetsIn, 0, _concat("LOST userBasic.assetsIn", type_));
                assertEq(lostUserBasic._reserved, 0, _concat("LOST userBasic._reserved", type_));
            }
        }
    }

    /// @dev userBasic is a public variable, but nt defined in any interface
    function _userBasic(CometMainInterface cometX, address user) internal returns (UserBasic memory userBasic) {
        bytes4 selector = bytes4(keccak256("userBasic(address)"));
        (, bytes memory data) = address(cometX).call(abi.encodeWithSelector(selector, user));

        (
            userBasic.principal,
            userBasic.baseTrackingIndex,
            userBasic.baseTrackingAccrued,
            userBasic.assetsIn,
            userBasic._reserved
        ) = abi.decode(data, (int104, uint64, uint64, uint16, uint8));
    }
}
