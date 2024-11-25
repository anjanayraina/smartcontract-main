// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/StandardToken.sol";
import "../contracts/AllowanceSheet.sol";
import "../contracts/BalanceSheet.sol";

contract StandardTokenTest is Test {
    StandardToken standardToken;
    AllowanceSheet allowanceSheet;
    BalanceSheet balanceSheet;
    address owner;
    address alice;
    address bob;
    address spender;

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        alice = address(0x1); // Token holder address
        bob = address(0x2);   // Recipient address
        spender = address(0x3); // Spender address

        // Deploy AllowanceSheet and BalanceSheet contracts
        allowanceSheet = new AllowanceSheet();
        balanceSheet = new BalanceSheet();

        // Deploy StandardToken contract
        standardToken = new StandardToken();

        // Set BalanceSheet and AllowanceSheet in StandardToken
        vm.startPrank(address(this));
        standardToken.setBalanceSheet(address(balanceSheet));
        standardToken.setAllowanceSheet(address(allowanceSheet));
        vm.stopPrank();
        // Verify owner is correctly set
        assertEq(standardToken.owner(), owner, "Owner should be correctly set");
    }

    function testSetAllowanceSheet() public {
        // Verify the allowance sheet is correctly set
        vm.startPrank(address(this));
        assertEq(address(standardToken.allowances()), address(allowanceSheet), "AllowanceSheet should be correctly set");
       vm.stopPrank();

    }

    function testSetBalanceSheet() public {
        // Verify the balance sheet is correctly set
        assertEq(address(standardToken.balances()), address(balanceSheet), "BalanceSheet should be correctly set");
    }

    function testApprove() public {
        // Approve spender for Alice
        vm.prank(alice);
        standardToken.approve(spender, 100);

        // Verify the allowance
        uint256 allowance = standardToken.allowance(alice, spender);
        assertEq(allowance, 100, "Allowance should match the approved value");
    }

    function testTransferFrom() public {
        // Add balance to Alice and set allowance for spender
        balanceSheet.addBalance(alice, 200);
        vm.prank(alice);
        standardToken.approve(spender, 100);

        // Spender transfers tokens from Alice to Bob
        vm.prank(spender);
        standardToken.transferFrom(alice, bob, 50);

        // Verify balances
        uint256 aliceBalance = standardToken.balanceOf(alice);
        uint256 bobBalance = standardToken.balanceOf(bob);

        assertEq(aliceBalance, 150, "Alice's balance should be reduced by the transferred amount");
        assertEq(bobBalance, 50, "Bob's balance should match the transferred amount");

        // Verify remaining allowance
        uint256 remainingAllowance = standardToken.allowance(alice, spender);
        assertEq(remainingAllowance, 50, "Remaining allowance should be reduced correctly");
    }

    function testIncreaseApproval() public {
        // Increase approval for spender
        vm.prank(alice);
        standardToken.approve(spender, 50);

        vm.prank(alice);
        standardToken.increaseApproval(spender, 50);

        // Verify the updated allowance
        uint256 allowance = standardToken.allowance(alice, spender);
        assertEq(allowance, 100, "Allowance should reflect the increased value");
    }

    function testDecreaseApproval() public {
        // Set and then decrease approval for spender
        vm.prank(alice);
        standardToken.approve(spender, 100);

        vm.prank(alice);
        standardToken.decreaseApproval(spender, 40);

        // Verify the updated allowance
        uint256 allowance = standardToken.allowance(alice, spender);
        assertEq(allowance, 60, "Allowance should reflect the decreased value");
    }

    function testTransferFromExceedingAllowanceShouldRevert() public {
        // Add balance to Alice and set allowance for spender
        balanceSheet.addBalance(alice, 200);
        vm.prank(alice);
        standardToken.approve(spender, 50);

        // Attempt to transfer more than the allowance
        vm.prank(spender);
        vm.expectRevert(); // Exceeds allowance
        standardToken.transferFrom(alice, bob, 100);
    }

    function testTransferFromExceedingBalanceShouldRevert() public {
        // Add balance to Alice but no sufficient funds
        balanceSheet.addBalance(alice, 50);
        vm.prank(alice);
        standardToken.approve(spender, 100);

        // Attempt to transfer more than Alice's balance
        vm.prank(spender);
        vm.expectRevert(); // Exceeds balance
        standardToken.transferFrom(alice, bob, 100);
    }
}
