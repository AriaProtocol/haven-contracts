pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {CometInterface} from "contracts/CometInterface.sol";
import {IERC20} from "contracts/IERC20.sol";

contract Fork_BorrowReserves_Test is Test {
    address public constant USDC_MARKET_Ethereum = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address public constant USDC_Ethereum = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH_Ethereum = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    CometInterface public comet = CometInterface(USDC_MARKET_Ethereum);

    // borrower data
    address public borrower;
    uint256 public constant WETH_BORROW_AMOUNT = 30_000 ether;

    uint256 public ethereumFork;

    function setUp() public {
        ethereumFork = vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        assertEq(vm.activeFork(), ethereumFork);

        borrower = makeAddr("borrower");
        deal(WETH_Ethereum, borrower, WETH_BORROW_AMOUNT);

        vm.prank(borrower);
        IERC20(WETH_Ethereum).approve(USDC_MARKET_Ethereum, type(uint256).max);
    }

    // @dev Borrow all reserves from the market, making utilization > 100%
    function testFork_borrowReserves_Over100Utilization() public {
        vm.startPrank(borrower);

        comet.supply(WETH_Ethereum, WETH_BORROW_AMOUNT);

        // Borrowing reserves
        uint256 usdcBal = IERC20(USDC_Ethereum).balanceOf(address(comet));
        comet.withdraw(USDC_Ethereum, usdcBal);

        // check, emtpy reserves
        {
            int256 reserves = comet.getReserves();
            uint256 utilization = comet.getUtilization();
            uint256 borrowRate = comet.getBorrowRate(utilization);
            emit log_named_int("Comet Reserves", reserves);
            emit log_named_uint("Total supply  ", comet.totalSupply());
            emit log_named_uint("Total borrow  ", comet.totalBorrow());
            // emit log_named_uint("Comet Borrow Rate", borrowRate);
            assertGe(comet.borrowBalanceOf(borrower), usdcBal, "not borrowed ALL reserves");
            assertEq(IERC20(USDC_Ethereum).balanceOf(address(comet)), 0, "reserves left in market");
            assertTrue(utilization > comet.factorScale(), "utilization <= 100%");
            assertNotEq(reserves, 0, "issue: reserves reset to 0");
        }
    }
}
