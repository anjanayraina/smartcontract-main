// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Claimable.sol";
import "./SafeMath.sol";

contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address tokenHolder, address spender, uint256 value) public onlyOwner {
        allowanceOf[tokenHolder][spender] = allowanceOf[tokenHolder][spender].add(value);
    }

    function subAllowance(address tokenHolder, address spender, uint256 value) public onlyOwner {
        allowanceOf[tokenHolder][spender] = allowanceOf[tokenHolder][spender].sub(value);
    }

    function setAllowance(address tokenHolder, address spender, uint256 value) public onlyOwner {
        allowanceOf[tokenHolder][spender] = value;
    }

    
}

// Owner : 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
//   Standard Token :  0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
//   Allowance Sheet :  0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f