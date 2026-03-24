### 1. Acteurs du système

| Rôle | Acteurs | Action |
|------|---------|--------|
| **Lit** | Citoyens, acheteurs, banques, géomètres | Consulter le registre |
| **Écrit** | Notaires, mairie, services de l'État | Enregistrer une transaction |
| **Valide** | Nœuds du réseau (mairies, chambre des notaires, cadastre) | Approuver et confirmer |

### 2. Type de blockchain : Consortium 

- Les données immobilières sont sensibles (noms, montants) → pas de blockchain publique
- Plusieurs acteurs distincts doivent se faire confiance mutuellement (mairies, notaires, État) → pas de blockchain privée centralisée chez un seul acteur
- Le consortium (ex : mairies + chambre des notaires + cadastre) partage la gouvernance

### 3. Trois apports de valeur

1. **Immutabilité** : une transaction enregistrée ne peut plus être falsifiée rétroactivement
2. **Désintermédiation partielle** : la vérification d'un titre de propriété ne dépend plus d'un notaire unique — elle est vérifiable directement
3. **Traçabilité complète** : l'historique complet de chaque bien (ventes successives, héritages) est auditable en permanence

### 4. Deux limitations à anticiper

1. **RGPD** : les données personnelles (noms des propriétaires, montants) ne peuvent pas être effacées d'une blockchain — nécessite de stocker des données chiffrées ou des références hachées, pas les données brutes on-chain
2. **Gouvernance et coût de déploiement** : mettre d'accord toutes les mairies de France sur un protocole commun est un défi organisationnel et financier majeur (interopérabilité, maintenance des nœuds)

### 5. Schéma d'architecture

```
┌─────────────────────────────────────────────────────┐
│              RÉSEAU CONSORTIUM                       │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Mairie  │  │ Notaires │  │  Cadastre (État) │  │
│  │  (Nœud) │  │  (Nœud) │  │     (Nœud)       │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │             │                  │             │
│       └─────────────┴──────────────────┘            │
│                      │                               │
│              [Blockchain partagée]                   │
│         (Hyperledger Fabric / Besu)                 │
│                                                      │
└─────────────────────────────────────────────────────┘
         ↑                              ↑
   Écriture via API               Lecture publique
   (notaire authentifié)          (citoyen / banque)
```
