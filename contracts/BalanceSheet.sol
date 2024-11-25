// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Claimable.sol";
import "./SafeMath.sol";

contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;
    uint256  totalSupply_;
    function getTotalSupply() public view returns(uint256){
        return totalSupply_;
    }
    function addBalance(address addr, uint256 value) public onlyOwner {
        balanceOf[addr] = balanceOf[addr].add(value);
        totalSupply_+=value;
    }

    function subBalance(address addr, uint256 value) public onlyOwner {
        balanceOf[addr] = balanceOf[addr].sub(value);
        totalSupply_-=value;
    }

    function setBalance(address addr, uint256 value) public onlyOwner {
        if (value < balanceOf[addr]){
            totalSupply_-=value;
        }
        else{
            totalSupply_+=value;
        }
        balanceOf[addr] = value;

    }


}