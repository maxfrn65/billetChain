## Exercice 1 — Compteur protégé (30 min)

### Objectif

Manipuler les bases : variables d'état, fonctions publiques, contrôle d'accès simple.

### Énoncé

Écrire un contrat `Counter` avec :

- Une variable `uint256 public count` initialisée à 0
- Une variable `address public immutable owner` qui reçoit `msg.sender` au constructeur
- Une fonction `increment()` qui incrémente `count` de 1 (n'importe qui peut l'appeler)
- Une fonction `decrement()` qui décrémente `count` de 1, **uniquement appelable par l'owner**, et qui revert si `count == 0`
- Une fonction `reset()` qui remet `count` à 0, **uniquement appelable par l'owner**
- Un event `Counted(address indexed by, uint256 newValue)` émis à chaque modification

### Critères d'acceptation

| Test | Comportement attendu |
|------|---------------------|
| `count()` initial | Retourne `0` |
| `increment()` puis `count()` | Retourne `1` |
| `increment()` × 5 | `count() == 5` |
| `decrement()` depuis non-owner | Revert |
| `decrement()` depuis owner quand `count == 0` | Revert |
| `reset()` depuis owner après increment | `count() == 0` |

### Bonus

- Ajouter `incrementBy(uint256 n)` qui revert si `n > 100`
- Limiter `increment()` à 1 appel par bloc et par adresse (utiliser `mapping(address => uint256)`)