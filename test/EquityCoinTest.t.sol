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

    bytes32 validHash = keccak256("valid");

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        alice = address(0x1);
        bob = address(0x2);
        carol = address(0x3);

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
        // Add Alice and Bob as verified addresses
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        // Mint tokens to Alice
        equityCoin.mint(alice, 100);

        // Attempt to transfer tokens during the locking period
        vm.prank(alice);
        vm.expectRevert("cannot transfer tokens during locking period of 12 months");
        equityCoin.transfer(bob, 50);
    }

    function testDisableLockingPeriod() public {
        // Disable the locking period
        equityCoin.enableLockingPeriod(false);
        assertFalse(equityCoin.lockingPeriodEnabled(), "Locking period should be disabled");

        // Add Alice and Bob as verified addresses
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        // Mint tokens to Alice
        equityCoin.mint(alice, 100);

        // Transfer tokens from Alice to Bob
        vm.prank(alice);
        equityCoin.transfer(bob, 50);

        // Verify balances
        assertEq(equityCoin.balanceOf(alice), 50, "Alice's balance should decrease");
        assertEq(equityCoin.balanceOf(bob), 50, "Bob's balance should increase");
    }

    function testUpdateVerifiedAddress() public {
        // Add Alice as a verified address
        equityCoin.addVerified(alice, validHash);

        // Update the verification hash
        bytes32 newHash = keccak256("updated");
        equityCoin.updateVerified(alice, newHash);

        // Verify the updated hash
        assertTrue(equityCoin.hasHash(alice, newHash), "Alice's hash should be updated");
    }

    function testRemoveVerifiedAddress() public {
        // Add Alice as a verified address
        equityCoin.addVerified(alice, validHash);

        // Mint tokens to Alice
        equityCoin.mint(alice, 100);

        // Burn Alice's tokens
        vm.prank(address(equityCoin));
        balanceSheet.setBalance(alice, 0);

        // Remove Alice as a verified address
        equityCoin.removeVerified(alice);

        // Verify Alice is no longer verified
        assertFalse(equityCoin.isVerified(alice), "Alice should no longer be a verified address");
    }

    function testTransferFrom() public {
    // Add Alice and Bob as verified addresses
    equityCoin.addVerified(alice, validHash);
    equityCoin.addVerified(bob, validHash);

    // Disable the locking period
    equityCoin.enableLockingPeriod(false);

    // Mint tokens to Alice
    equityCoin.mint(alice, 200);

    // Approve spender to transfer tokens from Alice
    address spender = address(0x6);
    vm.prank(alice);
    equityCoin.approve(spender, 100);

    // Spender transfers tokens from Alice to Bob
    vm.prank(spender);
    equityCoin.transferFrom(alice, bob, 50);

    // Verify balances
    assertEq(equityCoin.balanceOf(alice), 150, "Alice's balance should decrease by 50");
    assertEq(equityCoin.balanceOf(bob), 50, "Bob's balance should increase by 50");

    // Verify allowance is reduced
    uint256 remainingAllowance = equityCoin.allowance(alice, spender);
    assertEq(remainingAllowance, 50, "Remaining allowance should decrease by 50");

    // Verify Bob is now a shareholder
    assertTrue(equityCoin.isHolder(bob), "Bob should be a shareholder");

    // Verify Alice is still a shareholder
    assertTrue(equityCoin.isHolder(alice), "Alice should still be a shareholder");
}

function testTransferFromFailsIfNotVerified() public {
    // Add Alice as a verified address, but not Bob
            equityCoin.enableLockingPeriod(false);

    equityCoin.addVerified(alice, validHash);
    address spender = address(0x6);

    // Mint tokens to Alice
    equityCoin.mint(alice, 200);

    // Approve spender to transfer tokens from Alice
    vm.prank(alice);
    equityCoin.approve(spender, 100);

    // Attempt to transfer tokens from Alice to Bob (unverified address)
    vm.prank(spender);
    vm.expectRevert("address not verified");
    equityCoin.transferFrom(alice, bob, 50);
}

    function testCancelAndReissue() public {
        // Add Alice and Carol as verified addresses
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(carol, validHash);

        // Mint tokens to Alice
        equityCoin.mint(alice, 100);

        // Cancel Alice's address and reissue tokens to Carol
        equityCoin.cancelAndReissue(alice, carol);

        // Verify balances
        assertEq(equityCoin.balanceOf(alice), 0, "Alice's balance should be zero");
        assertEq(equityCoin.balanceOf(carol), 100, "Carol's balance should match Alice's original balance");
    }

    function testHolderCount() public {
        // Add Alice and Bob as verified addresses
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        // Mint tokens to Alice and Bob
        equityCoin.mint(alice, 100);
        equityCoin.mint(bob, 50);

        // Verify holder count
        assertEq(equityCoin.holderCount(), 2, "There should be two token holders");
    }

    function testHolderAt() public {
        // Add Alice and Bob as verified addresses
        equityCoin.addVerified(alice, validHash);
        equityCoin.addVerified(bob, validHash);

        // Mint tokens to Alice and Bob
        equityCoin.mint(alice, 100);
        equityCoin.mint(bob, 50);

        // Verify holders at specific indices
        assertEq(equityCoin.holderAt(0), alice, "Alice should be the first holder");
        assertEq(equityCoin.holderAt(1), bob, "Bob should be the second holder");
    }
}
