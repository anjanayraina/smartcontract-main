// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/BalanceSheet.sol";

contract BalanceSheetTest is Test {
    BalanceSheet balanceSheet;
    address owner;
    address user;

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        user = address(0x1);   // Test user address

        // Deploy BalanceSheet contract
        balanceSheet = new BalanceSheet();

        // Verify the test contract is the owner
        assertEq(balanceSheet.owner(), owner, "Owner should be correctly set");
    }

    function testAddBalance() public {
        // Add balance to user
        uint256 value = 100;
        balanceSheet.addBalance(user, value);

        // Verify the balance was added
        uint256 balance = balanceSheet.balanceOf(user);
        assertEq(balance, value, "Balance should match the added value");
    }

    function testAddBalanceMultipleTimes() public {
        // Add balance to user twice
        balanceSheet.addBalance(user, 50);
        balanceSheet.addBalance(user, 50);

        // Verify the cumulative balance
        uint256 balance = balanceSheet.balanceOf(user);
        assertEq(balance, 100, "Balance should be cumulative");
    }

    function testSubtractBalance() public {
        // Set an initial balance
        balanceSheet.setBalance(user, 100);

        // Subtract balance
        balanceSheet.subBalance(user, 40);

        // Verify the balance was reduced
        uint256 balance = balanceSheet.balanceOf(user);
        assertEq(balance, 60, "Balance should be reduced correctly");
    }

    function testSubtractBalanceToZero() public {
        // Set an initial balance
        balanceSheet.setBalance(user, 100);

        // Subtract the full balance
        balanceSheet.subBalance(user, 100);

        // Verify the balance is zero
        uint256 balance = balanceSheet.balanceOf(user);
        assertEq(balance, 0, "Balance should be zero");
    }




    function testNonOwnerCannotModifyBalance() public {
        // Simulate a non-owner trying to modify balances
        address nonOwner = address(0x3);
        vm.prank(nonOwner); // Change msg.sender to nonOwner

        uint256 value = 100;

        // Expect revert for addBalance
        vm.expectRevert("Ownable: caller is not the owner");
        balanceSheet.addBalance(user, value);

        // Expect revert for subBalance
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        balanceSheet.subBalance(user, value);

        // Expect revert for setBalance
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        balanceSheet.setBalance(user, value);
    }

    function testSubtractBalanceBelowZeroShouldRevert() public {
        // Set an initial balance
        balanceSheet.setBalance(user, 50);

        // Attempt to subtract more than the available balance
        vm.expectRevert(); // No specific error in SafeMath, so generic revert
        balanceSheet.subBalance(user, 100);
    }


}
