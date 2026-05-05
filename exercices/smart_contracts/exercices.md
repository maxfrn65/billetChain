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

## Exercice 2 — Whitelist (45 min)

### Objectif

Pratiquer les mappings, modifiers, et le pattern d'authorisation d'adresses.

### Énoncé

Écrire un contrat `Whitelist` qui maintient une liste blanche d'adresses :

- `address public immutable admin`
- `mapping(address => bool) public isWhitelisted`
- `uint256 public whitelistedCount`
- `addToWhitelist(address user)` : seulement admin, revert si déjà whitelisté
- `removeFromWhitelist(address user)` : seulement admin, revert si non whitelisté
- `addBatch(address[] calldata users)` : seulement admin, ajoute toutes les adresses (ignore les doublons sans revert)
- `event Whitelisted(address indexed user)` et `event Unwhitelisted(address indexed user)`
- Une **custom error** `NotAdmin(address caller)` à la place d'un require avec string

### Critères d'acceptation

| Test | Comportement attendu |
|------|---------------------|
| `addToWhitelist(alice)` depuis admin | `isWhitelisted(alice) == true`, `whitelistedCount == 1` |
| `addToWhitelist(alice)` depuis non-admin | Revert avec `NotAdmin(caller)` |
| `addToWhitelist(alice)` deux fois | Le second revert |
| `removeFromWhitelist(alice)` puis `isWhitelisted(alice)` | Retourne `false` |
| `addBatch([alice, bob, alice, carol])` | Whitelistés : alice, bob, carol ; count = 3 |

### Bonus

- Ajouter une fonction `transferAdmin(address newAdmin)` (seulement admin)
- Ajouter un délai de 24h avant qu'une whitelist soit "active" (`mapping(address => uint256) activeFrom`)

## Exercice 3 — Splitter de paiement (60 min)

### Objectif

Manipuler des ETH dans un contrat, comprendre le pattern pull-payment, gérer plusieurs bénéficiaires avec parts proportionnelles.

### Énoncé

Écrire un contrat `PaymentSplitter` qui répartit les ETH reçus entre plusieurs bénéficiaires selon des parts (shares).

- Constructor `constructor(address[] memory _payees, uint256[] memory _shares)`
  - Revert si tableaux de longueurs différentes ou vides
  - Revert si une part est nulle
  - Revert si une adresse est `address(0)`
  - Stocker `mapping(address => uint256) public shares` et `uint256 public totalShares`
- Fonction `receive() external payable` : enregistre simplement les ETH reçus
- `pendingPayment(address account)` : retourne le montant que `account` peut retirer
  - Formule : `(totalReceived × shares[account] / totalShares) - alreadyReleased[account]`
- `release(address payable account)` : transfère `pendingPayment(account)` vers `account`
  - Revert si compte n'a pas de parts
  - Revert si rien à payer
  - Émettre `event PaymentReleased(address indexed to, uint256 amount)`
- Variables additionnelles : `uint256 totalReceived`, `mapping(address => uint256) released`

### Critères d'acceptation

| Test | Comportement attendu |
|------|---------------------|
| Payees: [Alice, Bob, Carol] avec shares [50, 30, 20], reçoit 10 ETH | `pendingPayment(Alice) == 5 ETH`, Bob = 3, Carol = 2 |
| Après release Alice puis nouveau dépôt 10 ETH | `pendingPayment(Alice) == 5 ETH` (10/20 du total) |
| `release(Alice)` deux fois sans nouveau dépôt | Le second revert "Nothing to release" |
| Constructor avec tableaux vides | Revert |
| Constructor avec longueurs différentes | Revert |

### Bonus

- Permettre l'ajout d'un nouveau payee après déploiement (admin-only)
- Supporter les retraits via ERC-20 en plus d'ETH (un mapping `released[token][account]`)

---

## Exercice 4 — Token ERC-20 « VotingToken » (60 min)

### Objectif

Étendre un ERC-20 avec une logique métier : pondération de vote.

### Énoncé

Créer `VotingToken` qui hérite de `ERC20` (OpenZeppelin) et permet aux détenteurs de **voter sur des propositions**.

- ERC-20 standard avec name = "Voting Token", symbol = "VOTE", supply initial = 1_000_000 × 10^18 mintés au déployeur
- `struct Proposal { string description; uint256 voteCount; bool exists; }`
- `Proposal[] public proposals`
- `mapping(uint256 => mapping(address => bool)) public voted` pour suivre qui a voté pour quoi
- `createProposal(string calldata description)` : n'importe qui peut créer une proposition (mais doit détenir au moins 1 VOTE)
- `vote(uint256 proposalId)` :
  - Revert si proposition inexistante
  - Revert si déjà voté pour cette proposition
  - Le poids du vote = `balanceOf(msg.sender)` au moment du vote
  - Incrémenter `proposals[proposalId].voteCount` du poids
- `topProposal()` : retourne `(uint256 id, uint256 voteCount)` pour la proposition leader

### Critères d'acceptation

| Test | Comportement attendu |
|------|---------------------|
| Déployement | `totalSupply == 1M × 10^18` |
| Alice avec 0 VOTE crée une proposition | Revert |
| Alice avec 100 VOTE crée et vote | `voteCount == 100 × 10^18` |
| Alice vote deux fois sur même proposition | Le second revert |
| 3 propositions, votes différents | `topProposal()` renvoie celle avec le plus haut score |

### Bonus

- Empêcher le double vote en transférant des tokens entre comptes (snapshot au moment du vote ou utiliser ERC20Votes)
- Ajouter une deadline par proposition