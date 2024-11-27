// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/BasicToken.sol";
import "../contracts/BalanceSheet.sol";

contract BasicTokenTest is Test {
    BasicToken basicToken;
    BalanceSheet balanceSheet;
    address owner;
    address alice;
    address bob;

    // Declare the Transfer event for testing purposes
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        owner = address(this); // The test contract acts as the owner
        alice = address(0x1); // First user address
        bob = address(0x2);   // Second user address

        // Deploy the BalanceSheet contract
        balanceSheet = new BalanceSheet();

        // Deploy the BasicToken contract
        basicToken = new BasicToken();

        // Set the BalanceSheet for the token
        basicToken.setBalanceSheet(address(balanceSheet));

        // Verify the owner of the BasicToken contract
        assertEq(basicToken.owner(), owner, "Owner should be correctly set");
    }

    function testSetBalanceSheet() public {
        // Verify the balance sheet is correctly set
        assertEq(address(basicToken.balances()), address(balanceSheet), "BalanceSheet should be correctly set");
    }

    function testAddBalance() public {
        // Add balance to Alice
        balanceSheet.addBalance(alice, 100);

        // Verify Alice's balance
        uint256 aliceBalance = basicToken.balanceOf(alice);
        assertEq(aliceBalance, 100, "Alice's balance should match the added amount");
    }


    function testTransferExceedsBalanceShouldRevert() public {
        // Add balance to Alice
        balanceSheet.addBalance(alice, 50);

        // Attempt to transfer more than Alice's balance
        vm.prank(alice);
        vm.expectRevert(); // SafeMath will throw for insufficient balance
        basicToken.transfer(bob, 100);
    }

    function testTransferToZeroAddressShouldRevert() public {
        // Add balance to Alice
        balanceSheet.addBalance(alice, 100);

        // Attempt to transfer to the zero address
        vm.prank(alice);
        vm.expectRevert(); // Requires `_to` not to be the zero address
        basicToken.transfer(address(0), 50);
    }

    function testTotalSupply() public {
        // Add balances to simulate minting
        balanceSheet.addBalance(alice, 100);
        balanceSheet.addBalance(bob, 200);

        // Verify total supply
        assertEq(basicToken.totalSupply(), 300, "Total supply should match the sum of balances");
    }

    function testBalanceOf() public {
        // Add balance to Alice
        balanceSheet.addBalance(alice, 100);

        // Check Alice's balance using balanceOf
        uint256 aliceBalance = basicToken.balanceOf(alice);
        assertEq(aliceBalance, 100, "Alice's balance should be 100");
    }

    function testBalanceOfZeroAddress() public {
        // Check balance of zero address
        uint256 zeroAddressBalance = basicToken.balanceOf(address(0));
        assertEq(zeroAddressBalance, 0, "Zero address should have 0 balance");
    }



    function testNonOwnerSetBalanceSheetShouldRevert() public {
        // Attempt to set balance sheet from a non-owner address
        address nonOwner = address(0x3);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        basicToken.setBalanceSheet(address(0x4));
    }
}
