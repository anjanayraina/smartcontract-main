// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/Claimable.sol";

contract ClaimableTest is Test {
    Claimable claimable;
    address owner;
    address newOwner;
    address unauthorized;

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        newOwner = address(0x1); // Address to transfer ownership to
        unauthorized = address(0x2); // Unauthorized address

        // Deploy Claimable contract
        claimable = new Claimable();

        // Verify the initial owner is set correctly
        assertEq(claimable.owner(), owner, "Owner should be correctly set");
    }

    function testTransferOwnership() public {
        // Transfer ownership to a new owner
        claimable.transferOwnership(newOwner);

        // Verify the pending owner is set
        assertEq(claimable.pendingOwner(), newOwner, "Pending owner should be set correctly");
    }

    function testClaimOwnership() public {
        // Transfer ownership to a new owner
        claimable.transferOwnership(newOwner);

        // Verify the pending owner is set
        assertEq(claimable.pendingOwner(), newOwner, "Pending owner should be set correctly");

        // Claim ownership as the pending owner
        vm.prank(newOwner);
        claimable.claimOwnership();

        // Verify the ownership is transferred
        assertEq(claimable.owner(), newOwner, "Ownership should be transferred to the new owner");

        // Verify the pending owner is reset
        assertEq(claimable.pendingOwner(), address(0), "Pending owner should be reset");
    }

    function testOnlyPendingOwnerCanClaimOwnership() public {
        // Transfer ownership to a new owner
        claimable.transferOwnership(newOwner);

        // Attempt to claim ownership as an unauthorized address
        vm.prank(unauthorized);
        vm.expectRevert(); // Only pending owner can claim ownership
        claimable.claimOwnership();
    }

    function testOnlyOwnerCanTransferOwnership() public {
        // Attempt to transfer ownership as an unauthorized address
        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner"); // Only owner can transfer ownership
        claimable.transferOwnership(newOwner);
    }

    function testCannotClaimOwnershipWithoutPendingOwner() public {
        // Attempt to claim ownership without a pending owner
        vm.expectRevert(); // Pending owner is not set
        claimable.claimOwnership();
    }
}
