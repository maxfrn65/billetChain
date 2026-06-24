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

    error InvalidPrice();
    error StalePrice();

    function getLatestPrice() public view returns (int256 price, uint8 decimals) {
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        if (answer <= 0) revert InvalidPrice();
        if (block.timestamp - updatedAt > MAX_DELAY) revert StalePrice();

        return (answer, priceFeed.decimals());
    }

    mapping(address => uint256) public pendingWithdrawals;

    function eurToEth(uint256 eurAmount) public view returns (uint256) {
        (int256 price, uint8 decimals) = getLatestPrice();
        return (eurAmount * 1e18 * (10 ** decimals)) / uint256(price);
    }

    function buyTicket() external payable {
        require(nextTokenId < maxTickets, "Evenement complet");

        uint256 ethAmount = eurToEth(ticketPriceinEur);

        require(msg.value == ethAmount, "Paiement incorrect");

        initialPriceInEur[nextTokenId] = ticketPriceinEur;
        pendingWithdrawals[organizer] += msg.value;

        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }

    constructor(address _priceFeed, uint256 _maxTickets, uint256 _ticketPriceinEur) ERC721("BilletChain", "TICKET") {
        organizer = msg.sender;
        priceFeed = IPriceFeed(_priceFeed);
        maxTickets = _maxTickets;
        ticketPriceinEur = _ticketPriceinEur;
    }
}