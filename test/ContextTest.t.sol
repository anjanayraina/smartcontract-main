// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/Context.sol";

contract ContextTest is Test {
    ContextImplementation context; // Helper contract to test Context functionality
    address testSender;

    function setUp() public {
        // Deploy the ContextImplementation helper contract
        context = new ContextImplementation();
        testSender = address(0x123); // Simulated test sender address
    }

    function testMsgSender() public {
        // Simulate a call from the testSender
        vm.prank(testSender);
        address sender = context.msgSender();

        // Verify that _msgSender returns the correct sender
        assertEq(sender, testSender, "msg.sender should match the test sender");
    }

    function testMsgData() public {
        // Simulate a call with specific calldata
        vm.prank(testSender);
        bytes memory data = abi.encodeWithSignature("testFunction(uint256)", 12345);
        vm.expectCall(address(context), data);
        context.testFunction(12345);

        // Verify that _msgData returns the correct data
        bytes memory msgData = context.msgData();
        assertEq(msgData, data, "msg.data should match the calldata used");
    }
}

// Helper contract to allow instantiation of the abstract Context contract
contract ContextImplementation is Context {
    function msgSender() public view returns (address) {
        return _msgSender();
    }

    function msgData() public view returns (bytes calldata) {
        return _msgData();
    }

    function testFunction(uint256 value) public {
        // Dummy function to test msg.data
        require(value > 0, "Value must be positive");
    }
}
