// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

contract MockPriceFeed is IPriceFeed {
    int256 private _answer;
    uint256 private _updatedAt;
    uint8 private _decimals;

    constructor(int256 answer_, uint8 decimals_, uint256 updatedAt_) {
        _answer = answer_;
        _decimals = decimals_;
        _updatedAt = updatedAt_;
    }

    function setAnswer(int256 answer_, uint256 updatedAt_) external {
        _answer = answer_;
        _updatedAt = updatedAt_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, _answer, _updatedAt, _updatedAt, 1);
    }
}
