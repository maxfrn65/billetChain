import hashlib, json, time

class Bloc:
    def __init__(self, index, transactions, hash_precedent):
        self.index = index
        self.timestamp = time.time()
        self.transactions = transactions
        self.hash_precedent = hash_precedent
        self.nonce = 0
        self.hash = self.calculer_hash()

    def calculer_hash(self):
        contenu = json.dumps({
            "index": self.index,
            "timestamp": self.timestamp,
            "transactions": self.transactions,
            "hash_precedent": self.hash_precedent,
            "nonce": self.nonce
        }, sort_keys=True)
        return hashlib.sha256(contenu.encode()).hexdigest()

    def miner(self, difficulte):
        cible = "0" * difficulte
        while not self.hash.startswith(cible):
            self.nonce += 1
            self.hash = self.calculer_hash()
        print(f"Bloc {self.index} miné ! Nonce={self.nonce} | Hash={self.hash[:20]}...")


class Blockchain:
    def __init__(self):
        self.difficulte = 5
        self.chaine = [self._bloc_genesis()]

    def _bloc_genesis(self):
        genesis = Bloc(0, ["Bloc Genesis"], "0" * 64)
        genesis.miner(self.difficulte)
        return genesis

    def ajouter_bloc(self, transactions):
        dernier = self.chaine[-1]
        nouveau = Bloc(len(self.chaine), transactions, dernier.hash)
        nouveau.miner(self.difficulte)
        self.chaine.append(nouveau)

    def est_valide(self):
        for i in range(1, len(self.chaine)):
            courant = self.chaine[i]
            precedent = self.chaine[i - 1]

            # Le hash stocké correspond-il au contenu actuel ?
            if courant.hash != courant.calculer_hash():
                print(f"Bloc {i} : hash corrompu !")
                return False

            # Le lien prev_hash est-il intact ?
            if courant.hash_precedent != precedent.hash:
                print(f"Bloc {i} : lien brisé avec le bloc précédent !")
                return False

        return True


# --- Démonstration ---
if __name__ == "__main__":
    bc = Blockchain()
    bc.ajouter_bloc(["Alice → Bob : 1.5 ETH"])
    bc.ajouter_bloc(["Bob → Charlie : 0.8 ETH"])
    bc.ajouter_bloc(["Charlie → Diana : 2.0 ETH"])

    print(f"\nBlockchain valide : {bc.est_valide()}")

    # BONUS : Falsification
    print("\n--- Tentative de falsification du bloc 1 ---")
    bc.chaine[1].transactions = ["Alice → Bob : 100 ETH"]
    # Le hash n'est pas recalculé → incohérence détectée
    print(f"Blockchain valide après falsification : {bc.est_valide()}")