// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;
    address public immutable owner;

    error NotOwner(address caller);
    error TooLarge(uint256 amount);
    error UnderZero();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    function increment() external  {
        count += 1; 
    }

    function incrementBy(uint256 n) external  {
        if(n > 100) revert TooLarge(n);
        count += n;
    }

    function getCount() external view returns (uint256){
        return count;
    }

    function decrement() external onlyOwner {
        if(count == 0) revert UnderZero();
        count -= 1;
    }

    function reset() external onlyOwner {
        count = 0;
    }
}
