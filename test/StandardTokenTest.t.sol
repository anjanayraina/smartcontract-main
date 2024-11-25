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
        // Initialize addresses
        owner = address(this); // Test contract acts as the owner
        alice = address(0x1); // Alice's address
        bob = address(0x2); // Bob's address
        spender = address(0x3); // Spender's address

        // Deploy contracts
        allowanceSheet = new AllowanceSheet();
        balanceSheet = new BalanceSheet();
        standardToken = new StandardToken();

        // Transfer ownership of AllowanceSheet and BalanceSheet to StandardToken
        vm.startPrank(owner);
        allowanceSheet.transferOwnership(address(standardToken));
        balanceSheet.transferOwnership(address(standardToken));
        standardToken.setAllowanceSheet(address(allowanceSheet));
        standardToken.setBalanceSheet(address(balanceSheet));
        vm.stopPrank();
        vm.startPrank(address(standardToken));
        allowanceSheet.claimOwnership();
        vm.stopPrank();
    }

    function testApprove() public {
        // Add some balance to Alice's account
        vm.prank(owner);
        balanceSheet.addBalance(alice, 100);

        // Alice approves the spender
        vm.prank(alice);
        standardToken.approve(spender, 100);

        // Verify the allowance
        
        uint256 allowance = standardToken.allowance(alice, spender);
        assertEq(allowance, 100, "Allowance should match the approved value");
    }

    function testTransferFrom() public {
        // Add balance to Alice and set allowance for spender
        vm.prank(owner);
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

    function testTransferFromExceedingAllowanceShouldRevert() public {
        // Add balance to Alice and set allowance for spender
        vm.prank(owner);
        balanceSheet.addBalance(alice, 200);

        vm.prank(alice);
        standardToken.approve(spender, 50);

        // Attempt to transfer more than the allowance
        vm.prank(spender);
        vm.expectRevert(); // Exceeds allowance
        standardToken.transferFrom(alice, bob, 100);
    }

    function testTransferFromExceedingBalanceShouldRevert() public {
        // Add balance to Alice but insufficient funds
        vm.prank(owner);
        balanceSheet.addBalance(alice, 50);

        vm.prank(alice);
        standardToken.approve(spender, 100);

        // Attempt to transfer more than Alice's balance
        vm.prank(spender);
        vm.expectRevert(); // Exceeds balance
        standardToken.transferFrom(alice, bob, 100);
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
}
