"""
Demo 02 — Cryptographie Blockchain en Python
Formation Utopios — Module 2 : Cryptographie et Sécurité

Run: pip install ecdsa
     python demo02_cryptographie.py
"""
import hashlib
import json
import time
from typing import List


# ============================================================
# PARTIE 1 — SHA-256 et l'effet avalanche
# ============================================================

def demo_sha256():
    print("=" * 60)
    print("PARTIE 1 — SHA-256 ET L'EFFET AVALANCHE")
    print("=" * 60)

    # Démontrer l'effet avalanche : 1 caractère different = hash totalement different
    messages = [
        "Formation Blockchain Utopios",
        "Formation Blockchain Utopios.",   # un point de plus
        "formation Blockchain Utopios",    # minuscule initiale
        "Formation Blockchain Utopios!",   # point d'exclamation
        "",                                # chaine vide
    ]

    print("\nEffet avalanche :")
    for msg in messages:
        h = hashlib.sha256(msg.encode()).hexdigest()
        label = repr(msg) if msg else '""  (vide)'
        print(f"  SHA256({label})")
        print(f"    = {h}\n")

    # SHA-256 est déterministe
    msg = "même message"
    h1 = hashlib.sha256(msg.encode()).hexdigest()
    h2 = hashlib.sha256(msg.encode()).hexdigest()
    print(f"Déterminisme : SHA256(\"{msg}\") calculé 2 fois")
    print(f"  Résultat 1 : {h1}")
    print(f"  Résultat 2 : {h2}")
    print(f"  Identiques : {h1 == h2}\n")

    # Chaînage de hash (simulation de blocs)
    print("Chaînage de hash (simulation 3 blocs) :")
    prev_hash = "0" * 64
    for i in range(1, 4):
        data = f"bloc-{i}-donnees"
        combined = prev_hash + data
        block_hash = hashlib.sha256(combined.encode()).hexdigest()
        print(f"  Bloc {i} : SHA256(prev + data) = {block_hash[:32]}...")
        prev_hash = block_hash


# ============================================================
# PARTIE 2 — Signatures numériques ECDSA
# ============================================================

def demo_ecdsa():
    print("\n" + "=" * 60)
    print("PARTIE 2 — SIGNATURES NUMERIQUES ECDSA")
    print("=" * 60)

    try:
        from ecdsa import SigningKey, VerifyingKey, SECP256k1, BadSignatureError
    except ImportError:
        print("  ERREUR : pip install ecdsa")
        return

    # Générer une paire de clés (équivalent d'un wallet Ethereum/Bitcoin)
    print("\n[1] Génération des clés (courbe secp256k1 — même que Bitcoin/Ethereum)")
    private_key = SigningKey.generate(curve=SECP256k1)
    public_key = private_key.get_verifying_key()

    print(f"  Clé privée  : {private_key.to_string().hex()}")
    print(f"  Clé publique: {public_key.to_string().hex()[:60]}...")
    print("  -> La clé privée ne doit JAMAIS être partagée")
    print("  -> La clé publique est partageable, elle permet de vérifier")

    # Signer une transaction
    print("\n[2] Signature d'une transaction")
    transaction = {
        "sender": "Alice",
        "receiver": "Bob",
        "amount": 50,
        "timestamp": 1711000000
    }
    tx_str = json.dumps(transaction, sort_keys=True)
    tx_hash = hashlib.sha256(tx_str.encode()).digest()

    signature = private_key.sign(tx_hash)

    print(f"  Transaction : {tx_str}")
    print(f"  Hash TX     : {tx_hash.hex()}")
    print(f"  Signature   : {signature.hex()[:60]}...")

    # Vérification par un nœud du réseau
    print("\n[3] Vérification de la signature (ce que fait chaque nœud)")
    try:
        public_key.verify(signature, tx_hash)
        print("  VALIDE — la transaction est authentique et non modifiée")
    except BadSignatureError:
        print("  INVALIDE")

    # Cas 1 : données falsifiées (montant changé)
    print("\n[4] Tentative de falsification (montant 50 -> 5000)")
    fake_transaction = dict(transaction)
    fake_transaction["amount"] = 5000
    fake_str = json.dumps(fake_transaction, sort_keys=True)
    fake_hash = hashlib.sha256(fake_str.encode()).digest()

    try:
        public_key.verify(signature, fake_hash)
        print("  ACCEPTE (ne devrait pas arriver)")
    except BadSignatureError:
        print("  DETECTEE — la signature ne correspond pas aux données modifiées")

    # Cas 2 : mauvaise clé publique (quelqu'un d'autre)
    print("\n[5] Tentative de vérification avec la mauvaise clé publique")
    other_private_key = SigningKey.generate(curve=SECP256k1)
    other_public_key = other_private_key.get_verifying_key()

    try:
        other_public_key.verify(signature, tx_hash)
        print("  ACCEPTE (ne devrait pas arriver)")
    except BadSignatureError:
        print("  DETECTEE — la clé publique ne correspond pas au signataire")

    # Cas 3 : signer avec une autre clé et vérifier avec la bonne
    print("\n[6] Bob essaie de signer AU NOM d'Alice (usurpation)")
    bob_key = SigningKey.generate(curve=SECP256k1)
    fake_sig = bob_key.sign(tx_hash)

    try:
        public_key.verify(fake_sig, tx_hash)
        print("  ACCEPTE (ne devrait pas arriver)")
    except BadSignatureError:
        print("  DETECTEE — Bob ne peut pas signer au nom d'Alice")


# ============================================================
# PARTIE 3 — Arbre de Merkle
# ============================================================

class MerkleTree:
    """Arbre de Merkle complet avec preuve d'inclusion."""

    def __init__(self, transactions: List[str]):
        self.transactions = transactions
        self.leaves = [self._hash(tx) for tx in transactions]
        self.root, self.levels = self._build_tree(self.leaves)

    def _hash(self, data: str) -> str:
        return hashlib.sha256(data.encode()).hexdigest()

    def _hash_pair(self, left: str, right: str) -> str:
        return hashlib.sha256((left + right).encode()).hexdigest()

    def _build_tree(self, leaves: List[str]):
        levels = [leaves[:]]
        current_level = leaves[:]

        while len(current_level) > 1:
            if len(current_level) % 2 != 0:
                current_level.append(current_level[-1])
            next_level = [
                self._hash_pair(current_level[i], current_level[i + 1])
                for i in range(0, len(current_level), 2)
            ]
            levels.append(next_level)
            current_level = next_level

        return current_level[0] if current_level else self._hash(""), levels

    def get_proof(self, index: int) -> List[dict]:
        """Retourne la preuve d'inclusion (chemin de Merkle) pour une feuille."""
        proof = []
        nodes = self.leaves[:]

        while len(nodes) > 1:
            if len(nodes) % 2 != 0:
                nodes.append(nodes[-1])

            sibling = index + 1 if index % 2 == 0 else index - 1
            if sibling < len(nodes):
                proof.append({
                    "hash": nodes[sibling],
                    "position": "right" if index % 2 == 0 else "left"
                })
            index //= 2
            nodes = [
                self._hash_pair(nodes[i], nodes[i + 1])
                for i in range(0, len(nodes), 2)
            ]

        return proof

    def verify_proof(self, leaf_data: str, proof: List[dict], root: str) -> bool:
        """Vérifie qu'une transaction appartient au bloc sans tout re-calculer."""
        current = self._hash(leaf_data)
        for step in proof:
            if step["position"] == "right":
                current = self._hash_pair(current, step["hash"])
            else:
                current = self._hash_pair(step["hash"], current)
        return current == root

    def display(self):
        """Affiche l'arbre niveau par niveau."""
        print("\nStructure de l'arbre de Merkle :")
        for i, level in enumerate(reversed(self.levels)):
            label = "Racine" if i == len(self.levels) - 1 else f"Niveau {len(self.levels) - 1 - i}"
            print(f"  {label}: ", end="")
            for h in level:
                print(h[:8] + "..", end=" ")
            print()


def demo_merkle():
    print("\n" + "=" * 60)
    print("PARTIE 3 — ARBRE DE MERKLE")
    print("=" * 60)

    transactions = [
        '{"from":"Alice","to":"Bob","amount":50}',
        '{"from":"Bob","to":"Charlie","amount":25}',
        '{"from":"Charlie","to":"Diana","amount":10}',
        '{"from":"Diana","to":"Eve","amount":5}',
        '{"from":"Eve","to":"Frank","amount":3}',
        '{"from":"Frank","to":"Alice","amount":1}',
    ]

    print(f"\n{len(transactions)} transactions dans le bloc")
    tree = MerkleTree(transactions)
    print(f"Racine de Merkle : {tree.root}")

    print("\nFeuilles (hash des transactions) :")
    for i, (tx, leaf) in enumerate(zip(transactions, tree.leaves)):
        print(f"  [{i}] {leaf[:20]}... <- {tx[:40]}...")

    tree.display()

    # Vérification SPV
    print("\n--- Vérification SPV (client léger) ---")
    target_index = 2
    target_tx = transactions[target_index]
    proof = tree.get_proof(target_index)

    print(f"Question : la transaction [{target_index}] est-elle dans ce bloc ?")
    print(f"Transaction : {target_tx}")
    print(f"Preuve ({len(proof)} hashes au lieu de {len(transactions)}) :")
    for step in proof:
        print(f"  [{step['position']}] {step['hash'][:20]}...")

    valid = tree.verify_proof(target_tx, proof, tree.root)
    print(f"Résultat : Transaction présente = {valid}")

    # Falsification
    print("\n--- Détection de falsification ---")
    fake_tx = '{"from":"Alice","to":"Bob","amount":99999}'
    valid_fake = tree.verify_proof(fake_tx, proof, tree.root)
    print(f"Transaction falsifiée présente : {valid_fake}")

    # Impact d'une modification sur la racine
    print("\n--- Impact d'une modification sur la racine ---")
    original_root = tree.root
    modified_txs = transactions[:]
    modified_txs[0] = '{"from":"Alice","to":"Bob","amount":99999}'
    modified_tree = MerkleTree(modified_txs)
    print(f"Racine originale : {original_root[:32]}...")
    print(f"Racine modifiée  : {modified_tree.root[:32]}...")
    print(f"Identiques       : {original_root == modified_tree.root}")
    print("-> Modifier 1 transaction sur 1 million change la racine entière")


# ============================================================
# PARTIE 4 — Génération d'une adresse Bitcoin
# ============================================================

def demo_adresse_blockchain():
    print("\n" + "=" * 60)
    print("PARTIE 4 — GENERATION D'UNE ADRESSE BLOCKCHAIN")
    print("=" * 60)

    try:
        from ecdsa import SigningKey, SECP256k1
    except ImportError:
        print("  ERREUR : pip install ecdsa")
        return

    private_key = SigningKey.generate(curve=SECP256k1)
    public_key_bytes = private_key.get_verifying_key().to_string()

    print(f"\nEtape 1 — Cle privee (256 bits) :")
    print(f"  {private_key.to_string().hex()}")

    print(f"\nEtape 2 — Cle publique non compressée (512 bits) :")
    print(f"  04{public_key_bytes.hex()[:40]}...")

    sha256_result = hashlib.sha256(public_key_bytes).digest()
    print(f"\nEtape 3 — SHA256(cle publique) :")
    print(f"  {sha256_result.hex()}")

    ripemd160 = hashlib.new("ripemd160")
    ripemd160.update(sha256_result)
    hash160 = ripemd160.digest()
    print(f"\nEtape 4 — RIPEMD160(SHA256) = Hash160 :")
    print(f"  {hash160.hex()}")

    versioned = b"\x00" + hash160
    print(f"\nEtape 5 — Prefixe reseau (0x00 = mainnet Bitcoin) :")
    print(f"  {versioned.hex()}")

    checksum = hashlib.sha256(hashlib.sha256(versioned).digest()).digest()[:4]
    print(f"\nEtape 6 — Checksum (4 premiers octets de SHA256(SHA256())) :")
    print(f"  {checksum.hex()}")

    address_bytes = versioned + checksum
    ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = int.from_bytes(address_bytes, "big")
    address = ""
    while num > 0:
        num, rem = divmod(num, 58)
        address = ALPHABET[rem] + address
    leading = len(address_bytes) - len(address_bytes.lstrip(b"\x00"))
    address = ALPHABET[0] * leading + address

    print(f"\nEtape 7 — Adresse Bitcoin (Base58Check) :")
    print(f"  {address}")

    print("\n  -> Cette adresse est publique (partageable)")
    print("  -> Retrouver la cle privee depuis l'adresse est infaisable (securite 128 bits)")


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    print("=" * 60)
    print("DEMO 02 — CRYPTOGRAPHIE BLOCKCHAIN")
    print("Formation Utopios — Module 2")
    print("=" * 60)

    demo_sha256()
    demo_ecdsa()
    demo_merkle()
    demo_adresse_blockchain()

    print("\n" + "=" * 60)
    print("FIN DE LA DEMO CRYPTOGRAPHIE")
    print("=" * 60)
