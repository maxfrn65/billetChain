// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function increment() external  {
        count += 1; 
    }

    function incrementBy(uint256 n) external  {
        count += n;
    }

    function getCount() external view returns (uint256){
        return count;
    }

    function decrement() external {
        count -= 1;
    }

    function reset() external  {
        count = 0;
    }
}
