// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IPriceFeed {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract BilletChain is ERC721 {
    IPriceFeed public priceFeed;
    address public immutable organizer;

    uint256 public constant MAX_DELAY = 3600;
    uint256 public immutable maxTickets;
    uint256 public immutable ticketPriceinEur;
    uint256 public nextTokenId;

    mapping(uint256 => uint256) public initialPriceInEur;

    constructor(address _priceFeed, uint256 _maxTickets, uint256 _ticketPriceinEur) ERC721("BilletChain", "TICKET") {
        organizer = msg.sender;
        priceFeed = IPriceFeed(_priceFeed);
        maxTickets = _maxTickets;
        ticketPriceinEur = _ticketPriceinEur;
    }
}