// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/Ownable.sol";

contract OwnableTest is Test {
    OwnableImplementation ownable; // Helper contract to test Ownable behavior
    address owner;
    address newOwner;
    address unauthorized;

    function setUp() public {
        owner = address(this); // Test contract acts as the owner
        newOwner = address(0x1); // New owner address
        unauthorized = address(0x2); // Unauthorized address

        // Deploy OwnableImplementation contract
        ownable = new OwnableImplementation();

        // Verify the deployer is the initial owner
        assertEq(ownable.owner(), owner, "Owner should be correctly set to deployer");
    }

    function testTransferOwnership() public {
        // Transfer ownership to a new owner
        ownable.transferOwnership(newOwner);

        // Verify ownership transfer
        assertEq(ownable.owner(), newOwner, "Ownership should transfer to the new owner");
    }

    function testTransferOwnershipToZeroAddressReverts() public {
        // Attempt to transfer ownership to the zero address
        vm.expectRevert("Ownable: new owner is the zero address");
        ownable.transferOwnership(address(0));
    }

    function testOnlyOwnerCanTransferOwnership() public {
        // Attempt ownership transfer from an unauthorized account
        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner");
        ownable.transferOwnership(newOwner);
    }

    function testRenounceOwnership() public {
        // Renounce ownership
        ownable.renounceOwnership();

        // Verify the contract has no owner
        assertEq(ownable.owner(), address(0), "Owner should be the zero address after renouncing ownership");
    }

    function testOnlyOwnerCanRenounceOwnership() public {
        // Attempt to renounce ownership from an unauthorized account
        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner");
        ownable.renounceOwnership();
    }
}

contract OwnableImplementation is Ownable {}
