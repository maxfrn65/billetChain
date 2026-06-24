// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Demo 07 — Contrats upgradeables : le code est immuable, mais...
 * Journée Solidity avancée — Utopios
 *
 * Problème : une fois déployé, le bytecode d'un contrat NE CHANGE PLUS.
 * Comment corriger un bug ou ajouter une feature ?
 *
 * Réponse : le pattern PROXY. Les utilisateurs parlent toujours au PROXY
 * (même adresse, même état/storage), qui DÉLÈGUE l'exécution à un contrat
 * d'implémentation (la "logique") que l'on peut remplacer.
 *
 * Cette démo illustre le mécanisme à la main (pédagogique).
 * En production : OpenZeppelin UUPS / Transparent Proxy + outils Hardhat/Foundry.
 */

/// Implémentation V1 : un simple coffre qui stocke un nombre.
contract BoxV1 {
    // ⚠️ L'ORDRE des variables = le "storage layout". Le proxy partage CE layout.
    uint256 public value;

    event ValueChanged(uint256 newValue);

    function store(uint256 v) external {
        value = v;
        emit ValueChanged(v);
    }

    function version() external pure returns (string memory) {
        return "V1";
    }
}

/// Implémentation V2 : ajoute increment() SANS casser le layout (on n'enlève rien,
/// on n'insère rien avant `value` — on ne fait qu'ajouter du comportement).
contract BoxV2 {
    uint256 public value; // même slot 0 que V1 → l'état est préservé

    event ValueChanged(uint256 newValue);

    function store(uint256 v) external {
        value = v;
        emit ValueChanged(v);
    }

    // NOUVELLE fonctionnalité ajoutée par l'upgrade
    function increment() external {
        value += 1;
        emit ValueChanged(value);
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}

/**
 * Proxy minimal : garde l'adresse de l'implémentation et délègue tous les appels
 * via `delegatecall` (exécute le code de l'impl DANS le storage du proxy).
 */
contract SimpleProxy {
    // ⚠️ POINT CLÉ : on NE déclare PAS `address public implementation;` en slot 0,
    // car BoxV1.value occupe AUSSI le slot 0. Un delegatecall écraserait l'adresse
    // d'implémentation → collision de storage → contrat cassé.
    //
    // Solution (EIP-1967) : ranger implementation et admin dans des slots "exotiques"
    // calculés par hash, qu'aucune implémentation raisonnable n'utilisera.
    bytes32 private constant _IMPL_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // = keccak256("eip1967.proxy.implementation") - 1
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // = keccak256("eip1967.proxy.admin") - 1

    constructor(address impl) {
        _setSlot(_IMPL_SLOT, impl);
        _setSlot(_ADMIN_SLOT, msg.sender);
    }

    function implementation() public view returns (address) { return _getSlot(_IMPL_SLOT); }
    function admin() public view returns (address) { return _getSlot(_ADMIN_SLOT); }

    /// L'admin remplace la logique → "upgrade". L'état (slot 0 = value) reste intact.
    function upgradeTo(address newImpl) external {
        require(msg.sender == _getSlot(_ADMIN_SLOT), "not admin");
        _setSlot(_IMPL_SLOT, newImpl);
    }

    function _setSlot(bytes32 slot, address value) private {
        assembly { sstore(slot, value) }
    }
    function _getSlot(bytes32 slot) private view returns (address a) {
        assembly { a := sload(slot) }
    }

    /// Toute autre fonction est déléguée à l'implémentation courante.
    fallback() external payable {
        address impl = _getSlot(_IMPL_SLOT);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/*
 * À MONTRER EN SÉANCE :
 *  1. Déployer BoxV1, puis SimpleProxy(BoxV1.address).
 *  2. Dans Remix : "At Address" → charger l'ABI de BoxV1 SUR l'adresse du proxy.
 *  3. store(42) via le proxy → value == 42 (état dans le proxy).
 *  4. Déployer BoxV2, appeler proxy.upgradeTo(BoxV2.address).
 *  5. Recharger l'ABI BoxV2 sur le proxy → value vaut TOUJOURS 42, et increment() existe !
 *
 * Point critique : NE JAMAIS changer l'ordre/typage des variables existantes entre
 * deux versions (storage collision). On ne fait qu'AJOUTER à la fin.
 */
