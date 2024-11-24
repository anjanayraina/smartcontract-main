// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/EquityCoin.sol";

contract MintingTest is Test {
    EquityCoin equityCoin;
    address owner;
    address alice;

    function setUp() public {
        owner = address(this);
        alice = address(0x1);

        equityCoin = new EquityCoin();

        // Owner adds verified addresses
        equityCoin.addVerified(alice, bytes32("AliceHash"));
    }

    function testMint() public {
        // Owner mints tokens to Alice
        uint256 amount = 100;
        equityCoin.mint(alice, amount);

        // Check Alice's balance
        uint256 aliceBalance = equityCoin.balanceOf(alice);
        assertEq(aliceBalance, amount);
    }

    function testMintToUnverifiedAddress() public {
        // Attempt to mint to an unverified address
        address unverified = address(0x2);
        uint256 amount = 100;

        vm.expectRevert("address not verified");
        equityCoin.mint(unverified, amount);
    }
}
