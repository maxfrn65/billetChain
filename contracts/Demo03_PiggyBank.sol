// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PiggyBank {
    address public immutable owner;
    uint256 public immutable lockUntil;

    uint256 public goal;
    uint256 public totalDeposited;

    event Deposited(address indexed from, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed to, uint256 amount);
    event GoalUpdated(uint256 newGoal);

    error NotOwner();
    error StillLocked(uint256 unlockAt, uint256 currentTime);
    error GoalNotReached(uint256 balance, uint256 goal);
    error TransferFailed();

    constructor(uint256 _lockSeconds, uint256 _goal) payable {
        owner = msg.sender;
        lockUntil = block.timestamp + _lockSeconds;
        goal = _goal;

    
        if (msg.value > 0) {
            totalDeposited = msg.value;
            emit Deposited(msg.sender, msg.value, msg.value);
        }
    }

    receive() external payable {
        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value, address(this).balance);
    }

    function setGoal(uint256 _goal) external {
        if (msg.sender != owner) revert NotOwner();
        goal = _goal;
        emit GoalUpdated(_goal);
    }

    function withdraw() external {
        if (msg.sender != owner) revert NotOwner();
        if (block.timestamp < lockUntil) revert StillLocked(lockUntil, block.timestamp);

        uint256 currentBalance = address(this).balance;
        if (currentBalance < goal) revert GoalNotReached(currentBalance, goal);

        (bool ok, ) = payable(owner).call{value: currentBalance}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(owner, currentBalance);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= lockUntil) return 0;
        return lockUntil - block.timestamp;
    }

}