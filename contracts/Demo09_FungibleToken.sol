// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Demo 09 — Token FONGIBLE (ERC-20)
 * Journée Solidity avancée — Utopios
 *
 * FONGIBLE = interchangeable. 1 token vaut 1 token, exactement comme 1 € vaut 1 €.
 * Vos tokens n'ont pas d'identité : seul compte le SOLDE (un nombre).
 *
 * Cas d'usage : monnaies, points de fidélité, parts, stablecoins, jetons de gouvernance.
 *
 * On hérite d'OpenZeppelin pour ne PAS réimplémenter le standard (transfer, approve,
 * allowance, balanceOf, events Transfer/Approval...). On n'ajoute que notre logique métier :
 *   - un mint réservé au propriétaire (création de monnaie contrôlée)
 *   - un burn ouvert à tous (chacun peut détruire SES tokens)
 *   - un cap (plafond d'émission) pour la rareté
 */
contract LoyaltyToken is ERC20, Ownable {
    /// Plafond maximal de tokens pouvant exister (anti-inflation).
    uint256 public immutable cap;

    error CapExceeded(uint256 attempted, uint256 cap);

    constructor(uint256 cap_)
        ERC20("Loyalty Points", "LOYAL")
        Ownable(msg.sender)
    {
        cap = cap_;
    }

    /// Création de tokens — réservée au propriétaire, plafonnée par le cap.
    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > cap) {
            revert CapExceeded(totalSupply() + amount, cap);
        }
        _mint(to, amount);
    }

    /// Destruction — chacun peut brûler ses propres tokens (réduit le totalSupply).
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
