// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Whitelist {
    address public immutable admin;
    mapping(address => bool) public isWhitelisted;
    uint256 public whitelistedCount;

    event Whitelisted(address indexed user);
    event Unwhitelisted(address indexed user);

    error NotAdmin(address caller);
    error AlreadyWhitelisted();
    error NotWhitelisted();

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        _;
    }

    function addToWhitelist(address user) external onlyAdmin {
        if (isWhitelisted[user]) revert AlreadyWhitelisted();
        isWhitelisted[user] = true;
        whitelistedCount += 1;
        emit Whitelisted(user);
    }

    function removeFromWhitelist(address user) external onlyAdmin {
        if (!isWhitelisted[user]) revert NotWhitelisted();
        isWhitelisted[user] = false;
        whitelistedCount -= 1;
        emit Unwhitelisted(user);
    }

    function addBatch(address[] calldata users) external onlyAdmin {
        uint256 len = users.length;
        for (uint256 i = 0; i < len; i++) {
            address u = users[i];
            if (!isWhitelisted[u]) {
                isWhitelisted[u] = true;
                whitelistedCount += 1;
                emit Whitelisted(u);
            }
        }
    }

    function getWhiteList(address user) external view returns  (bool) {
        if (!isWhitelisted[user]) revert NotWhitelisted();
        return isWhitelisted[user];
    }
}
