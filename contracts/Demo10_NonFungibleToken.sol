// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Demo 10 — Token NON FONGIBLE (ERC-721 / NFT)
 * Journée Solidity avancée — Utopios
 *
 * NON FONGIBLE = unique. Chaque token a un IDENTIFIANT propre (tokenId) et UN
 * propriétaire. Mon NFT #7 n'est PAS équivalent à votre NFT #12.
 *
 * Opposé de l'ERC-20 :
 *   ERC-20  : un SOLDE (un nombre)        -> balanceOf(addr) = 42
 *   ERC-721 : une CARTE D'IDENTITÉ par token -> ownerOf(7) = Alice
 *
 * Cas d'usage : œuvres d'art, tickets, certificats, objets de jeu, titres de propriété.
 *
 * Le contrat ne stocke pas l'image (trop cher en gas) : il stocke une URI
 * (souvent un lien IPFS) qui pointe vers les métadonnées (image + attributs).
 *
 * On illustre aussi le modèle d'autorisation approve / transferFrom, source n°1
 * de bugs : pour qu'un tiers (ex. une marketplace) déplace votre NFT, il faut
 * d'abord l'AUTORISER.
 */
contract GameItem is ERC721URIStorage, Ownable {
    uint256 private _nextId; // identifiant auto-incrémenté

    constructor() ERC721("Game Item", "ITEM") Ownable(msg.sender) {}

    /// Fabrique un nouvel objet unique et lui attache ses métadonnées (URI).
    /// @return id l'identifiant du NFT créé.
    function mint(address to, string memory tokenURI_)
        external
        onlyOwner
        returns (uint256 id)
    {
        id = _nextId++;
        _safeMint(to, id);          // crée le NFT et l'attribue à `to`
        _setTokenURI(id, tokenURI_); // associe l'URI (lien IPFS vers l'image/attributs)
    }

    /// Nombre total de NFT déjà créés (les ids vont de 0 à totalMinted-1).
    function totalMinted() external view returns (uint256) {
        return _nextId;
    }
}
