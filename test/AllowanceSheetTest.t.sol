// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/AllowanceSheet.sol";

contract AllowanceSheetTest is Test {
    AllowanceSheet allowanceSheet;
    address owner;
    address tokenHolder;
    address spender;

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        tokenHolder = address(0x1); // Token holder
        spender = address(0x2); // Spender

        // Deploy AllowanceSheet contract
        allowanceSheet = new AllowanceSheet();

        // Verify owner is set correctly
        assertEq(allowanceSheet.owner(), owner, "Owner should be correctly set");
    }

    function testAddAllowance() public {
        // Add allowance for spender
        uint256 value = 100;
        allowanceSheet.addAllowance(tokenHolder, spender, value);

        // Verify allowance was added
        uint256 allowance = allowanceSheet.allowanceOf(tokenHolder, spender);
        assertEq(allowance, value, "Allowance should match the added value");
    }

    function testAddAllowanceMultipleTimes() public {
        // Add allowance twice
        allowanceSheet.addAllowance(tokenHolder, spender, 50);
        allowanceSheet.addAllowance(tokenHolder, spender, 50);

        // Verify cumulative allowance
        uint256 allowance = allowanceSheet.allowanceOf(tokenHolder, spender);
        assertEq(allowance, 100, "Allowance should be cumulative");
    }

    function testSubtractAllowance() public {
        // Set an initial allowance
        allowanceSheet.setAllowance(tokenHolder, spender, 100);

        // Subtract allowance
        allowanceSheet.subAllowance(tokenHolder, spender, 40);

        // Verify allowance was reduced
        uint256 allowance = allowanceSheet.allowanceOf(tokenHolder, spender);
        assertEq(allowance, 60, "Allowance should be reduced correctly");
    }

    function testSubtractAllowanceToZero() public {
        // Set an initial allowance
        allowanceSheet.setAllowance(tokenHolder, spender, 100);

        // Subtract allowance fully
        allowanceSheet.subAllowance(tokenHolder, spender, 100);

        // Verify allowance is zero
        uint256 allowance = allowanceSheet.allowanceOf(tokenHolder, spender);
        assertEq(allowance, 0, "Allowance should be zero");
    }

    function testSetAllowance() public {
        // Set allowance directly
        allowanceSheet.setAllowance(tokenHolder, spender, 200);

        // Verify allowance
        uint256 allowance = allowanceSheet.allowanceOf(tokenHolder, spender);
        assertEq(allowance, 200, "Allowance should match the set value");
    }

    function testNonOwnerCannotModifyAllowance() public {
        // Simulate a non-owner trying to modify allowances
        address nonOwner = address(0x3);
        vm.prank(nonOwner); // Change msg.sender to nonOwner

        uint256 value = 100;

        // Expect revert for addAllowance
        vm.expectRevert("Ownable: caller is not the owner");
        allowanceSheet.addAllowance(tokenHolder, spender, value);

        // Expect revert for subAllowance
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        allowanceSheet.subAllowance(tokenHolder, spender, value);

        // Expect revert for setAllowance
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        allowanceSheet.setAllowance(tokenHolder, spender, value);
    }

    function testSubtractAllowanceBelowZeroShouldRevert() public {
        // Set an initial allowance
        allowanceSheet.setAllowance(tokenHolder, spender, 50);

        // Attempt to subtract more than the allowance
        vm.expectRevert(); // No specific error in SafeMath, so generic revert
        allowanceSheet.subAllowance(tokenHolder, spender, 100);
    }
}
