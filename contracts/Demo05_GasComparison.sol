// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract GasNaive {
    uint256 public total;
    uint256[] public values;

    // Anti-pattern : on lit `values.length` et `total` (storage) à chaque tour de boucle.
    function sumAndStore(uint256[] calldata input) external {
        for (uint256 i = 0; i < values.length + input.length; i++) {
            // push un par un = une écriture storage par élément
        }
        for (uint256 i = 0; i < input.length; i++) {
            values.push(input[i]);     // SSTORE coûteux à chaque itération
            total = total + input[i];  // relit + réécrit `total` (storage) à chaque tour
        }
    }
}

contract GasOptimized {
    uint256 public total;
    uint256[] public values;

    // Bonnes pratiques :
    //  - calldata en entrée (pas de copie mémoire)
    //  - longueur mise en cache
    //  - accumulation dans une variable LOCALE (memory) puis 1 seule écriture storage
    //  - ++i non vérifié (unchecked) car i ne peut pas overflow ici
    function sumAndStore(uint256[] calldata input) external {
        uint256 len = input.length;        // cache de la longueur
        uint256 acc = total;               // 1 lecture storage
        for (uint256 i = 0; i < len; ) {
            values.push(input[i]);
            acc += input[i];               // accumulation en mémoire
            unchecked { ++i; }             // évite le check d'overflow inutile
        }
        total = acc;                       // 1 seule écriture storage du total
    }
}
