// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/MintableToken.sol";
import "../contracts/AllowanceSheet.sol";
import "../contracts/BalanceSheet.sol";

contract MintableTokenTest is Test {
    MintableToken mintableToken;
    AllowanceSheet allowanceSheet;
    BalanceSheet balanceSheet;
    address owner;
    address alice;

    function setUp() public {
        // Initialize addresses
        owner = address(this); // Test contract acts as the owner
        alice = address(0x1); // Alice's address

        // Deploy contracts
        allowanceSheet = new AllowanceSheet();
        balanceSheet = new BalanceSheet();
        mintableToken = new MintableToken();

        // Transfer ownership of AllowanceSheet and BalanceSheet to MintableToken
        vm.startPrank(owner);
        allowanceSheet.transferOwnership(address(mintableToken));
        balanceSheet.transferOwnership(address(mintableToken));
        mintableToken.setAllowanceSheet(address(allowanceSheet));
        mintableToken.setBalanceSheet(address(balanceSheet));
        vm.stopPrank();
        vm.startPrank(address(mintableToken));
        allowanceSheet.claimOwnership();
        vm.stopPrank();
    }

    function testMint() public {
        // Mint tokens for Alice
        uint256 mintAmount = 100;
        vm.prank(owner);
        bool success = mintableToken.mint(alice, mintAmount);

        // Verify the mint operation
        assertTrue(success, "Mint should return true");

        // Verify Alice's balance
        uint256 aliceBalance = mintableToken.balanceOf(alice);
        assertEq(aliceBalance, mintAmount, "Alice's balance should match the minted amount");

        // Verify total supply
        uint256 totalSupply = mintableToken.totalSupply();
        assertEq(totalSupply, mintAmount, "Total supply should match the minted amount");
    }

    function testMintTwice() public {
        // Mint tokens for Alice twice
        vm.prank(owner);
        mintableToken.mint(alice, 50);

        vm.prank(owner);
        mintableToken.mint(alice, 50);

        // Verify Alice's balance
        uint256 aliceBalance = mintableToken.balanceOf(alice);
        assertEq(aliceBalance, 100, "Alice's balance should match the total minted amount");

        // Verify total supply
        uint256 totalSupply = mintableToken.totalSupply();
        assertEq(totalSupply, 100, "Total supply should match the total minted amount");
    }

    function testMintByNonOwnerShouldRevert() public {
        // Attempt to mint tokens from a non-owner account
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        mintableToken.mint(alice, 100);
    }

    function testMintZeroAmount() public {
        // Mint zero tokens
        vm.prank(owner);
        bool success = mintableToken.mint(alice, 0);

        // Verify the mint operation
        assertTrue(success, "Mint should return true for zero amount");

        // Verify Alice's balance
        uint256 aliceBalance = mintableToken.balanceOf(alice);
        assertEq(aliceBalance, 0, "Alice's balance should remain zero");

        // Verify total supply
        uint256 totalSupply = mintableToken.totalSupply();
        assertEq(totalSupply, 0, "Total supply should remain zero");
    }

    function testMintToZeroAddressShouldRevert() public {
        // Attempt to mint tokens to the zero address
        vm.prank(owner);
        vm.expectRevert(); // Should revert for minting to zero address
        mintableToken.mint(address(0), 100);
    }
}
