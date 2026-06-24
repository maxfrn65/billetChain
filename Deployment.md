# Note de déploiement — BilletChain

Ce document résume le plan de déploiement et de configuration du smart contract BilletChain sur un réseau public de test.

---

### **1. Choix du réseau de test**
Pour déployer le contrat dans des conditions réelles, le choix se porte sur le réseau de test **Sepolia** (le testnet principal recommandé pour Ethereum). Ce réseau reproduit fidèlement le comportement d'Ethereum sans coût réel et dispose d'une infrastructure d'oracles Chainlink active et régulièrement mise à jour.

---

### **2. Paramètres d'initialisation (Constructeur)**
Lors du déploiement du contrat `BilletChain.sol`, trois paramètres doivent être passés au constructeur :

1.  **`_priceFeed` (address) :** L'adresse du contrat Oracle Chainlink pour le taux ETH/EUR sur le réseau cible (voir section suivante).
2.  **`_maxTickets` (uint256) :** La limite totale de billets disponibles à la vente (ex. `100`).
3.  **`_ticketPriceinEur` (uint256) :** Le prix nominal du billet en euros (ex. `50` pour un billet à 50 €).

---

### **3. Adresse de l'Oracle de taux de change (ETH / EUR)**
Pour obtenir le flux de prix officiel de la paire **ETH / EUR** sur le réseau de test **Sepolia** :

*   **Source de l'adresse :** L'adresse officielle doit être récupérée directement dans la documentation de Chainlink dédiée aux flux de prix Ethereum :  
    [https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1](https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1)
*   **Adresse sur Sepolia :** Dans l'onglet *Sepolia Testnet*, on recherche la paire `ETH / EUR`.  
    L'adresse du contrat price feed correspondante est :  
    `0x1a81afB8146aeFfCFc5E50e84e7F81214816aa1c`
*   **Configuration du constructeur :** C'est cette adresse `0x1a81afB8146aeFfCFc5E50e84e7F81214816aa1c` qui devra être passée comme paramètre `_priceFeed`.

---

### **4. Exemple de Script de déploiement (Foundry)**
Pour déployer ce contrat via Foundry sur Sepolia, la commande suivante peut être exécutée :

```bash
forge create --rpc-url <SEPOLIA_RPC_URL> \
             --private-key <VOTRE_CLE_PRIVEE> \
             contracts/BilletChain.sol:BilletChain \
             --constructor-args "0x1a81afB8146aeFfCFc5E50e84e7F81214816aa1c" 100 50
```
*(Où `100` est le nombre maximal de billets, et `50` est le prix nominal du billet en euros).*
