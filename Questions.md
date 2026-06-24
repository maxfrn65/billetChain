# Réponses aux questions

### **Q1 — Fondamentaux : déterminisme et données du monde réel**
*   **Déterminisme et Réplication :** Tous les nœuds de la blockchain doivent exécuter chaque transaction de manière identique pour parvenir au même état final (consensus). L'exécution doit donc être 100 % déterministe.
*   **Limitation du monde réel :** Un contrat ne peut pas faire d'appel API externe (ex. requête HTTP), car les réponses varient dans le temps et l'espace (ex. un prix fluctuant ou la météo). Si chaque nœud obtenait une valeur différente lors de sa validation, le consensus serait brisé. Les données réelles doivent être poussées sur la chaîne par des Oracles.

---

### **Q2 — Cryptographie : signature, clé privée et vérification**
*   **Clé privée et signature :** La clé privée (secrète) sert à signer cryptographiquement une transaction. La signature prouve l'identité de l'émetteur et garantit que la transaction n'a pas été modifiée durant son transport.
*   **Vérification :** Grâce à l'algorithme ECDSA, les nœuds du réseau peuvent mathématiquement déduire l'adresse publique de l'émetteur en combinant le contenu de la transaction et sa signature. Si elle correspond à `msg.sender`, la transaction est validée sans que la clé privée n'ait jamais été partagée.

---

### **Q3 — Tokens : unique (ERC-721) vs interchangeable (ERC-20)**
*   **Standard unique (ERC-721) :** Chaque billet correspond à un siège précis (historique d'achat propre, limite de revente unique). Les billets ne sont pas interchangeables et sont identifiés par un `tokenId` unique.
*   **Standard interchangeable (ERC-20) :** Idéal pour de la monnaie ou des jetons de boissons à échanger au bar de l'événement, où chaque jeton a exactement la même valeur qu'un autre.

---

### **Q4 — Sécurité : menaces et protections dans BilletChain**
Le contrat se protège contre deux failles majeures :
1.  **Réentrée (Reentrancy) :** Menace de vider le contrat en rappelant la fonction de retrait en boucle. Protection via le pattern **Checks-Effects-Interactions** : le solde de l'utilisateur est mis à 0 (`pendingWithdrawals[msg.sender] = 0`) *avant* de lui envoyer les fonds.
2.  **Déni de Service (DoS) sur transfert :** Menace de bloquer les ventes si un transfert direct de fonds vers un tiers échoue. Protection via le pattern **Pull Payment** : l'argent de la revente n'est pas envoyé automatiquement mais stocké sur le contrat. C'est le vendeur qui doit venir le réclamer lui-même via `withdraw()`.

---

### **Q5 — Gas : choix d'optimisations concrètes**
1.  **Variables `immutable` :** Les variables de configuration (`maxTickets`, `ticketPriceinEur`) sont insérées directement dans le bytecode compilé au déploiement. Cela évite d'utiliser le stockage persistant (Storage), très coûteux en gas lors des lectures.
2.  **Optimisation de la fonction de lecture :** 
    *   Utilisation du mot-clé `calldata` pour le tableau d'arguments pour éviter sa copie en mémoire.
    *   Incrémentation de l'index de la boucle dans un bloc `unchecked` pour sauter la vérification automatique de dépassement d'entier de Solidity 0.8.0.
