// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/SafeMath.sol";

contract SafeMathTest is Test {
    using SafeMath for uint256;

    function testAddition() public {
        uint256 a = 5;
        uint256 b = 10;
        uint256 result = a.add(b);

        assertEq(result, 15, "Addition result should be correct");
    }

    function testAdditionOverflow() public {
        uint256 a = type(uint256).max;
        uint256 b = 1;

        // Expect revert due to overflow
        vm.expectRevert();
        a.add(b);
    }

    function testSubtraction() public {
        uint256 a = 10;
        uint256 b = 5;
        uint256 result = a.sub(b);

        assertEq(result, 5, "Subtraction result should be correct");
    }

    function testSubtractionUnderflow() public {
        uint256 a = 5;
        uint256 b = 10;

        // Expect revert due to underflow
        vm.expectRevert();
        a.sub(b);
    }

    function testMultiplication() public {
        uint256 a = 3;
        uint256 b = 4;
        uint256 result = a.mul(b);

        assertEq(result, 12, "Multiplication result should be correct");
    }

    function testMultiplicationOverflow() public {
        uint256 a = type(uint256).max / 2 + 1;
        uint256 b = 2;

        // Expect revert due to overflow
        vm.expectRevert();
        a.mul(b);
    }

    function testDivision() public {
        uint256 a = 10;
        uint256 b = 2;
        uint256 result = a.div(b);

        assertEq(result, 5, "Division result should be correct");
    }

    function testDivisionByZero() public {
        uint256 a = 10;
        uint256 b = 0;

        // Expect revert due to division by zero
        vm.expectRevert();
        a.div(b);
    }
}
