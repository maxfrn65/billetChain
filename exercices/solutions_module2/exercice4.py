import hashlib

def h(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()

def h2(a: str, b: str) -> str:
    return hashlib.sha256((a + b).encode()).hexdigest()

# Transactions
txA = "Alice → Bob : 1 BTC"
txB = "Charlie → Diana : 0.5 BTC"
txC = "Eve → Frank : 2 BTC"
txD = "Grace → Hank : 0.3 BTC"

# Niveau 0 — feuilles
hA = h(txA)
hB = h(txB)
hC = h(txC)
hD = h(txD)

# Niveau 1
hAB = h2(hA, hB)
hCD = h2(hC, hD)

# Merkle Root
root = h2(hAB, hCD)

print("=== Arbre de Merkle ===")
print(f"Hash(A)  = {hA[:64]}...")
print(f"Hash(B)  = {hB[:64]}...")
print(f"Hash(C)  = {hC[:64]}...")
print(f"Hash(D)  = {hD[:64]}...")
print(f"Hash(AB) = {hAB[:64]}...")
print(f"Hash(CD) = {hCD[:64]}...")
print(f"Merkle Root = {root[:64]}...")