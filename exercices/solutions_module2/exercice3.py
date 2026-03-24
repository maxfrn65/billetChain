from ecdsa import SigningKey, VerifyingKey, SECP256k1, BadSignatureError
import hashlib

# ── 1. Génération d'une paire de clés ──────────────────────────────────────
cle_privee = SigningKey.generate(curve=SECP256k1)
cle_publique = cle_privee.get_verifying_key()

print("=== Clés générées ===")
print(f"Clé privée  : {cle_privee.to_string().hex()[:32]}...")
print(f"Clé publique: {cle_publique.to_string().hex()[:32]}...")

# Simulation d'une adresse Bitcoin (simplifiée)
adresse = hashlib.sha256(cle_publique.to_string()).hexdigest()[:40]
print(f"Adresse     : {adresse}")

# ── 2. Signature d'une transaction ─────────────────────────────────────────
tx_originale = "Alice envoie 0.5 BTC à Bob"
tx_falsifiee  = "Alice envoie 5 BTC à Bob"

signature = cle_privee.sign(tx_originale.encode())
print(f"\n=== Signature ===")
print(f"Transaction  : {tx_originale}")
print(f"Signature    : {signature.hex()[:32]}...")

# ── 3. Vérification — transaction originale ────────────────────────────────
print("\n=== Vérifications ===")
try:
    cle_publique.verify(signature, tx_originale.encode())
    print(f"'{tx_originale}' → Signature VALIDE")
except BadSignatureError:
    print(f"'{tx_originale}' → Signature INVALIDE")

# ── 4. Vérification — transaction falsifiée ────────────────────────────────
try:
    cle_publique.verify(signature, tx_falsifiee.encode())
    print(f"'{tx_falsifiee}' → Signature VALIDE")
except BadSignatureError:
    print(f"'{tx_falsifiee}' → Signature INVALIDE")

# ── BONUS : 3 paires de clés différentes ───────────────────────────────────
print("\n=== BONUS — 3 paires de clés ===")
for i in range(3):
    sk = SigningKey.generate(curve=SECP256k1)
    vk = sk.get_verifying_key()
    print(f"Paire {i+1} | Privée: {sk.to_string().hex()[:16]}... "
          f"| Publique: {vk.to_string().hex()[:16]}...")