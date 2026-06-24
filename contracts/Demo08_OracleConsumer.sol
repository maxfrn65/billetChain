// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


/// Interface minimale d'un price feed Chainlink (AggregatorV3Interface).
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

contract OracleConsumer {
    IPriceFeed public immutable priceFeed;

    /// Au-delà de ce délai, on considère le prix périmé (1 heure).
    uint256 public constant MAX_DELAY = 3600;

    error InvalidPrice();
    error StalePrice();

    /**
     * @param feed adresse du price feed.
     * Sepolia ETH/USD réel : 0x694AA1769357215DE4FAC081bf1f309aDC325306
     * En test : on passe l'adresse d'un MockPriceFeed.
     */
    constructor(address feed) {
        priceFeed = IPriceFeed(feed);
    }

    /// Dernier prix (ex. ETH/USD) + ses décimales. Sécurisé.
    function getLatestPrice() public view returns (int256 price, uint8 decimals) {
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        // ----- LES DEUX GARDE-FOUS DE SÉCURITÉ ORACLE -----
        if (answer <= 0) revert InvalidPrice();              // prix nul/négatif = anomalie
        if (block.timestamp - updatedAt > MAX_DELAY) revert StalePrice(); // donnée trop vieille

        return (answer, priceFeed.decimals());
    }

    /// Convertit un montant en wei (1e18) vers sa valeur en USD (sur 1e8).
    function ethToUsd(uint256 weiAmount) external view returns (uint256 usd) {
        (int256 price, ) = getLatestPrice();
        usd = (weiAmount * uint256(price)) / 1e18;
    }
}

/**
 * MockPriceFeed — un FAUX price feed pour les tests / la démo locale.
 * On peut lui faire dire n'importe quel prix, à n'importe quelle date.
 * (En prod, c'est Chainlink qui fournit le vrai contrat.)
 */
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
