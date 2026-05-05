// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HelloBockChain {

    string public message;
    address public immutable owner;
    uint256 public updateCount;

    event MessageUpdated(address indexed author, string oldMessage, string newMessage);

    constructor(string memory _initialMessage) {
        message = _initialMessage;
        owner = msg.sender;
        updateCount = 0;
    }

    function updateMessage(string calldata _message) external {
        require(bytes(_message).length > 0, "Message vide interdit");
        require(bytes(_message).length <= 280, "Message trop grand");
        string memory oldMessage = message;
        message = _message;
        updateCount++;
        emit MessageUpdated(msg.sender, oldMessage, message);
    }

    function getMessage() external view returns (string memory)  {
        return message;
    }
}