"""
Demo 01 — Mini-Blockchain en Python
Formation Utopios — Blockchain Fondamentaux

Run: python demo01_blockchain.py
"""
import hashlib
import json
import time
from typing import List, Dict


class Block:
    """Représente un bloc dans la blockchain."""

    def __init__(self, index: int, transactions: List[Dict],
                 previous_hash: str, nonce: int = 0):
        self.index = index
        self.timestamp = time.time()
        self.transactions = transactions
        self.previous_hash = previous_hash
        self.nonce = nonce
        self.hash = self.calculate_hash()

    def calculate_hash(self) -> str:
        block_data = json.dumps({
            "index": self.index,
            "timestamp": self.timestamp,
            "transactions": self.transactions,
            "previous_hash": self.previous_hash,
            "nonce": self.nonce
        }, sort_keys=True)
        return hashlib.sha256(block_data.encode()).hexdigest()

    def __repr__(self):
        return (f"Block(index={self.index}, "
                f"hash={self.hash[:16]}..., "
                f"prev={self.previous_hash[:16]}..., "
                f"txs={len(self.transactions)}, "
                f"nonce={self.nonce})")


class Blockchain:
    """Blockchain simple avec Proof of Work."""

    def __init__(self, difficulty: int = 4):
        self.chain: List[Block] = []
        self.pending_transactions: List[Dict] = []
        self.difficulty = difficulty
        self.mining_reward = 10
        self._create_genesis_block()

    def _create_genesis_block(self):
        genesis = Block(0, [
            {"type": "genesis", "data": "Formation Blockchain Utopios"},
            {"sender": "NETWORK", "receiver": "Alice", "amount": 200, "type": "initial"},
            {"sender": "NETWORK", "receiver": "Bob",   "amount": 100, "type": "initial"},
            {"sender": "NETWORK", "receiver": "Charlie","amount": 50,  "type": "initial"},
            {"sender": "NETWORK", "receiver": "Diana", "amount": 30,  "type": "initial"},
        ], "0" * 64)
        self.chain.append(genesis)
        print(f"Genesis block créé: {genesis.hash[:20]}...")

    def get_latest_block(self) -> Block:
        return self.chain[-1]

    def add_transaction(self, sender: str, receiver: str, amount: float) -> int:
        tx = {
            "sender": sender,
            "receiver": receiver,
            "amount": amount,
            "timestamp": time.time()
        }
        self.pending_transactions.append(tx)
        print(f"  Tx ajoutée: {sender} -> {receiver}: {amount} coins")
        return len(self.pending_transactions)

    def mine_pending_transactions(self, miner_address: str) -> Block:
        self.pending_transactions.append({
            "sender": "NETWORK",
            "receiver": miner_address,
            "amount": self.mining_reward,
            "timestamp": time.time(),
            "type": "mining_reward"
        })

        new_block = Block(
            index=len(self.chain),
            transactions=self.pending_transactions.copy(),
            previous_hash=self.get_latest_block().hash
        )

        print(f"\nMinage du bloc #{new_block.index} (difficulté: {self.difficulty})...")
        start_time = time.time()
        target = "0" * self.difficulty
        attempts = 0

        while not new_block.hash.startswith(target):
            new_block.nonce += 1
            new_block.hash = new_block.calculate_hash()
            attempts += 1

        elapsed = time.time() - start_time
        print(f"  Bloc miné en {elapsed:.2f}s ({attempts:,} tentatives)")
        print(f"  Hash: {new_block.hash}")
        print(f"  Nonce: {new_block.nonce}")

        self.chain.append(new_block)
        self.pending_transactions = []
        return new_block

    def is_chain_valid(self) -> bool:
        for i in range(1, len(self.chain)):
            current = self.chain[i]
            previous = self.chain[i - 1]

            if current.hash != current.calculate_hash():
                print(f"  ERREUR Bloc #{i}: hash invalide")
                return False

            if current.previous_hash != previous.hash:
                print(f"  ERREUR Bloc #{i}: lien avec bloc précédent cassé")
                return False

            if not current.hash.startswith("0" * self.difficulty):
                print(f"  ERREUR Bloc #{i}: preuve de travail invalide")
                return False

        print("  Chaine valide")
        return True

    def get_balance(self, address: str) -> float:
        balance = 0.0
        for block in self.chain:
            for tx in block.transactions:
                if tx.get("sender") == address:
                    balance -= tx["amount"]
                if tx.get("receiver") == address:
                    balance += tx["amount"]
        return balance

    def display_chain(self):
        print("\n" + "=" * 60)
        print("BLOCKCHAIN COMPLETE")
        print("=" * 60)
        for block in self.chain:
            print(f"\n--- Bloc #{block.index} ---")
            print(f"  Timestamp : {time.ctime(block.timestamp)}")
            print(f"  Hash      : {block.hash}")
            print(f"  Prev Hash : {block.previous_hash}")
            print(f"  Nonce     : {block.nonce}")
            print(f"  Transactions ({len(block.transactions)}):")
            for tx in block.transactions:
                if tx.get("type") == "genesis":
                    print(f"    [GENESIS] {tx['data']}")
                elif tx.get("type") == "mining_reward":
                    print(f"    [REWARD] -> {tx['receiver']}: +{tx['amount']} coins")
                else:
                    print(f"    {tx['sender']} -> {tx['receiver']}: {tx['amount']} coins")
        print("\n" + "=" * 60)


if __name__ == "__main__":
    print("=" * 60)
    print("DEMO 01 — MINI-BLOCKCHAIN EN PYTHON")
    print("Formation Utopios — Blockchain Fondamentaux")
    print("=" * 60)

    # --- Création de la blockchain ---
    print("\n[1] Création de la blockchain (difficulté: 4)")
    blockchain = Blockchain(difficulty=4)

    # --- Premier lot de transactions ---
    print("\n[2] Ajout de transactions (mempool)...")
    blockchain.add_transaction("Alice", "Bob", 50)
    blockchain.add_transaction("Bob", "Charlie", 25)
    blockchain.add_transaction("Charlie", "Diana", 10)

    # --- Minage ---
    blockchain.mine_pending_transactions("Mineur-1")

    # --- Deuxième lot ---
    print("\n[3] Nouveau lot de transactions...")
    blockchain.add_transaction("Alice", "Eve", 30)
    blockchain.add_transaction("Diana", "Alice", 5)

    blockchain.mine_pending_transactions("Mineur-2")

    # --- Affichage ---
    blockchain.display_chain()

    # --- Validation ---
    print("\n[4] Vérification de l'intégrité...")
    blockchain.is_chain_valid()

    # --- Soldes ---
    print("\n[5] Soldes finaux:")
    for addr in ["Alice", "Bob", "Charlie", "Diana", "Eve", "Mineur-1", "Mineur-2"]:
        print(f"  {addr}: {blockchain.get_balance(addr)} coins")

    # --- Tentative de falsification ---
    print("\n[6] Tentative de falsification du bloc #1...")
    original_amount = blockchain.chain[1].transactions[0]["amount"]
    blockchain.chain[1].transactions[0]["amount"] = 5000
    print(f"  Montant falsifié: {original_amount} -> 5000")
    result = blockchain.is_chain_valid()
    if not result:
        print("  -> La falsification est détectée par la validation")

    # --- Restauration et re-validation ---
    blockchain.chain[1].transactions[0]["amount"] = original_amount
    blockchain.chain[1].hash = blockchain.chain[1].calculate_hash()
    # Note : même restauré, le bloc #2 a encore l'ancien hash du bloc #1
    # -> cela montre que la chaîne est cassée durablement sans re-minage
