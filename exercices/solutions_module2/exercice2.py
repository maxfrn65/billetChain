import hashlib

def miner(message, difficulte):
    cible = "0" * difficulte
    nonce = 0
    while True:
        contenu = f"{message}{nonce}"
        h = hashlib.sha256(contenu.encode()).hexdigest()
        if h.startswith(cible):
            return nonce, h
        nonce += 1

message = "Alice envoie 1 BTC à Bob"

for diff in [2, 3, 4, 5, 6]:
    nonce, h = miner(message, diff)
    print(f"Difficulté {'0'*diff} | Nonce = {nonce:>10} | Hash = {h[:20]}...")