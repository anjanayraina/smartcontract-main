// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/EquityCoin.sol";
import "../contracts/BalanceSheet.sol";
import "../contracts/AllowanceSheet.sol";

contract EquityCoinTest is Test {
    EquityCoin equityCoin;
    BalanceSheet balanceSheet;
    AllowanceSheet allowanceSheet;

    address owner;
    address alice;
    address bob;
    address carol;
    address replacement;

    bytes32 validHash = keccak256("valid");
    bytes32 updatedHash = keccak256("updated");

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        alice = address(0x1);
        bob = address(0x2);
        carol = address(0x3);
        replacement = address(0x4);

        // Deploy dependent contracts
        balanceSheet = new BalanceSheet();
        allowanceSheet = new AllowanceSheet();

        // Deploy EquityCoin contract
        equityCoin = new EquityCoin();

        // Set BalanceSheet and AllowanceSheet
        vm.startPrank(owner);
        allowanceSheet.transferOwnership(address(equityCoin));
        balanceSheet.transferOwnership(address(equityCoin));
        equityCoin.setAllowanceSheet(address(allowanceSheet));
        equityCoin.setBalanceSheet(address(balanceSheet));
        vm.stopPrank();

        vm.startPrank(address(equityCoin));
        allowanceSheet.claimOwnership();
        balanceSheet.claimOwnership();
        vm.stopPrank();
    }

    function testConstructor() public {
        assertEq(equityCoin.name(), "EquityCoin", "Name should be set correctly");
        assertEq(equityCoin.symbol(), "EQTY", "Symbol should be set correctly");
        assertEq(equityCoin.lockingPeriodEnabled(), true, "Locking period should be enabled");
        assertEq(equityCoin.lockingPeriod(), block.timestamp + 365 days, "Locking period should be 365 days");
    }

    function testAddVerifiedAddress() public {
        equityCoin.addVerified(alice, validHash);
        assertTrue(equityCoin.isVerified(alice), "Alice should be a verified address");
    }

    function testTransferFailsDuringLockingPeriod() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);
        equityCoin.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert("cannot transfer tokens during locking period of 12 months");
        equityCoin.transfer(bob, 50);
    }

    function testDisableLockingPeriod() public {
        equityCoin.enableLockingPeriod(false);
        assertFalse(equityCoin.lockingPeriodEnabled(), "Locking period should be disabled");

        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        equityCoin.mint(alice, 100);

        vm.prank(alice);
        equityCoin.transfer(bob, 50);

        assertEq(equityCoin.balanceOf(alice), 50, "Alice's balance should decrease");
        assertEq(equityCoin.balanceOf(bob), 50, "Bob's balance should increase");
    }

    function testUpdateVerifiedAddress() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.updateVerified(alice, updatedHash);

        assertTrue(equityCoin.hasHash(alice, updatedHash), "Alice's hash should be updated");
    }

    function testRemoveVerifiedAddress() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.mint(alice, 100);

        vm.prank(address(equityCoin));
        balanceSheet.setBalance(alice, 0);

        equityCoin.removeVerified(alice);

        assertFalse(equityCoin.isVerified(alice), "Alice should no longer be a verified address");
    }

    function testTransferFrom() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);
        equityCoin.enableLockingPeriod(false);

        equityCoin.mint(alice, 200);

        address spender = address(0x6);
        vm.prank(alice);
        equityCoin.approve(spender, 100);

        vm.prank(spender);
        equityCoin.transferFrom(alice, bob, 50);

        assertEq(equityCoin.balanceOf(alice), 150, "Alice's balance should decrease by 50");
        assertEq(equityCoin.balanceOf(bob), 50, "Bob's balance should increase by 50");

        uint256 remainingAllowance = equityCoin.allowance(alice, spender);
        assertEq(remainingAllowance, 50, "Remaining allowance should decrease by 50");

        assertTrue(equityCoin.isHolder(bob), "Bob should be a shareholder");
        assertTrue(equityCoin.isHolder(alice), "Alice should still be a shareholder");
    }

    function testIsSuperseded() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(carol, validHash);

        equityCoin.mint(alice, 100);
        equityCoin.cancelAndReissue(alice, carol);

        assertTrue(equityCoin.isSuperseded(alice), "Alice's address should be superseded");
        assertFalse(equityCoin.isSuperseded(carol), "Carol's address should not be superseded");
    }

    function testGetCurrentFor() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(replacement, updatedHash);

        equityCoin.mint(alice, 100);
        equityCoin.cancelAndReissue(alice, replacement);

        assertEq(equityCoin.getCurrentFor(alice), replacement, "Replacement should be the current address for Alice");
        assertEq(equityCoin.getCurrentFor(replacement), replacement, "Replacement should return itself");
    }

    function testFindCurrentFor() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(replacement, updatedHash);
        equityCoin.addVerified(carol, validHash);

        equityCoin.mint(alice, 100);
        equityCoin.cancelAndReissue(alice, replacement);
        equityCoin.cancelAndReissue(replacement, carol);

        assertEq(equityCoin.getCurrentFor(alice), carol, "Carol should be the current address for Alice");
        assertEq(equityCoin.getCurrentFor(replacement), carol, "Carol should be the current address for Replacement");
        assertEq(equityCoin.getCurrentFor(carol), carol, "Carol should return itself");
    }

    function testsetLockingPeriod() public {
        equityCoin.setLockingPeriod(10);
        assertEq(equityCoin.lockingPeriod() , block.timestamp + 10 * 1 days);

    }

    function testPruneShareholders() public {
                equityCoin.enableLockingPeriod(false);

        equityCoin.addVerified(alice, validHash);

        equityCoin.mint(alice, 100);
        equityCoin.addVerified(bob, validHash);

        vm.prank(alice);
        equityCoin.transfer(bob, 100);

        assertFalse(equityCoin.isHolder(alice), "Alice should no longer be a shareholder");
        assertTrue(equityCoin.isHolder(bob), "Bob should be a shareholder");
    }

    function testHasHash() public {
        equityCoin.addVerified(alice, validHash);

        assertTrue(equityCoin.hasHash(alice, validHash), "Alice should have the valid hash");
        assertFalse(equityCoin.hasHash(alice, updatedHash), "Alice should not have the updated hash");

        equityCoin.updateVerified(alice, updatedHash);

        assertTrue(equityCoin.hasHash(alice, updatedHash), "Alice should have the updated hash");
        assertFalse(equityCoin.hasHash(alice, validHash), "Alice should not have the old hash");
    }

    function testHolderCount() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        equityCoin.mint(alice, 100);
        equityCoin.mint(bob, 50);

        assertEq(equityCoin.holderCount(), 2, "There should be two token holders");
    }

    function testHolderAt() public {
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        equityCoin.mint(alice, 100);
        equityCoin.mint(bob, 50);

        assertEq(equityCoin.holderAt(0), alice, "Alice should be the first holder");
        assertEq(equityCoin.holderAt(1), bob, "Bob should be the second holder");
    }
}
