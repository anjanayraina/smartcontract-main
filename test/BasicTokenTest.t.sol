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
        
        balanceSheet.transferOwnership(address(basicToken));
        vm.startPrank(owner);
        basicToken.setBalanceSheet(address(balanceSheet));
        vm.stopPrank();
        // Verify the owner of the BasicToken contract
        assertEq(basicToken.owner(), owner, "Owner should be correctly set");
    }

    function testSetBalanceSheet() public {
        // Verify the balance sheet is correctly set
        assertEq(address(basicToken.balances()), address(balanceSheet), "BalanceSheet should be correctly set");
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
