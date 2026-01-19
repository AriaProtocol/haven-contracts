pragma solidity ^0.8.15;

import {CometInterface} from "contracts/CometInterface.sol";

import {Fixture_3Sup_3Bor} from "test/forge/setup/Fixture_3Sup_3Bor.t.sol";

contract Comet_borrow_Over100Utilization_Test is Fixture_3Sup_3Bor {    
    function testFork_borrowReserves_Over100Utilization() public {
        vm.startPrank(lastBorrower);

        // lastBorrower supplies WETH
        weth.approve(address(comet), type(uint256).max);
        comet.supply(address(weth), 264e18);

        // lastBorrower borrows with all reserves (600k + 100k reserves)
        uint256 usdcBal = baseToken.balanceOf(address(comet));
        comet.withdraw(address(baseToken), usdcBal);

        // Check insolvency
        {
            int256 reserves = comet.getReserves();
            uint256 utilization = comet.getUtilization();
            uint256 borrowRate = comet.getBorrowRate(utilization);
            emit log_named_int("Comet Reserves", reserves);
            emit log_named_uint("Total supply  ", comet.totalSupply());
            emit log_named_uint("Total borrow  ", comet.totalBorrow());
            assertEq(reserves, int256(RESERVES), "issue: reserves updated");
            assertTrue(utilization > CometInterface(address(comet)).factorScale(), "utilization <= 100%");
            assertEq(baseToken.balanceOf(address(comet)), 0, "reserves left in market");
        }

        // Prices drop, WETH price halves, Comet absorb debt by liquidator calls
        {
            (,int256 price_,,,) = wethPriceFeed.latestRoundData();
            wethPriceFeed.setRoundData(39234, price_ / 2, 0, 0, 2);

            address[] memory absorbees =new address[](1);
            absorbees[0] = lastBorrower;

            vm.startPrank(absorber);
            comet.absorb(absorber, absorbees);
        }

        // IRL, liquidator can buy back seized collateral
    }
}
