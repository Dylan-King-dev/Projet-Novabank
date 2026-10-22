# NovaBank Core

Projet de conception et d'administration d'une base de données PostgreSQL pour une banque en ligne fictive, réalisé dans le cadre du Bachelor 2 Informatique.

## Objectifs

- Structurer les données bancaires avec PostgreSQL.
- Gérer les rôles, les privilèges et les accès aux données.
- Masquer certaines informations personnelles.
- Journaliser les modifications sensibles.
- Protéger le registre des transactions.
- Détecter certaines opérations potentiellement frauduleuses.
- Exécuter des virements et maintenir la cohérence des soldes.

## Environnement technique

- Ubuntu Server
- PostgreSQL 18
- SQL et PL/pgSQL
- Bash
- Git et GitHub

## Structure du projet

```text
novabank/
├── scripts/
│   └── 01_install_postgresql.sh
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_schemas.sql
│   ├── 02_create_tables.sql
│   ├── 03_seed_data.sql
│   ├── 04_create_roles.sql
│   ├── 05_grant_permissions.sql
│   ├── 06_create_views.sql
│   ├── 07_create_updatable_view.sql
│   ├── 08_create_materialized_view.sql
│   ├── 09_create_indexes.sql
│   ├── 10_audit_trigger.sql
│   ├── 11_attach_audit_triggers.sql
│   ├── 12_protect_ledger.sql
│   ├── 13_fraud_alert_trigger.sql
│   ├── 14_balance_trigger.sql
│   └── 15_create_procedures.sql
└── README.md
```

## Architecture de la base de données

Le projet utilise deux schémas principaux :

- `core` : données clients, comptes, transactions, virements et alertes antifraude.
- `audit` : journal des modifications apportées aux données sensibles.

Les scripts SQL numérotés organisent la création de la base, la préparation des données, la gestion des permissions et l'implémentation des mécanismes métier.

## Sécurité et contrôle des accès

Le projet met en œuvre :

- Des rôles distincts pour l'analyse, le support, l'application et l'audit.
- La vue `core.v_customers_masked` pour limiter l'exposition des informations personnelles.
- La vue `core.v_customer_kyc`, qui encadre les mises à jour autorisées du statut KYC.
- La journalisation des modifications sur les tables sensibles.
- La protection des transactions enregistrées contre les modifications et suppressions.
- Une procédure de virement `core.execute_transfer` configurée avec `SECURITY DEFINER`, un `search_path` explicite et des droits d'exécution contrôlés.

## Virements et détection de fraude

La procédure `core.execute_transfer` :

- Vérifie les paramètres et l'existence des comptes.
- Verrouille les comptes concernés pour limiter les conflits concurrents.
- Contrôle le solde disponible.
- Enregistre le virement et ses deux écritures comptables associées.

Les déclencheurs permettent également :

- De mettre à jour le solde d'un compte après l'insertion d'une transaction.
- De détecter les retraits d'au moins 5 000 €.
- De détecter au moins cinq virements sortants sur une période de dix minutes.

## Installation

Le script d'installation PostgreSQL se trouve dans `scripts/01_install_postgresql.sh`.

Les scripts du dossier `sql/` sont numérotés pour suivre les étapes de construction de la base. Ils doivent être exécutés dans l'ordre approprié, en tenant compte des dépendances et des prérequis de chaque script.

Avant de rejouer les scripts de création ou de chargement, vérifier leur contenu et utiliser un environnement de test adapté.

## Vérifications réalisées

Les tests effectués pendant le développement ont porté notamment sur :

- Les permissions des rôles.
- Le masquage des informations clients.
- Les restrictions de mise à jour de la vue KYC.
- La journalisation des modifications.
- Le refus de modification du registre des transactions.
- Les règles de détection de fraude.
- Les virements valides et les cas d'erreur.
- La configuration de sécurité de la procédure de virement.

Les opérations temporaires utilisées pour certains tests ont été annulées avec `ROLLBACK` afin de ne pas conserver leurs effets.

## Livrables

- Scripts SQL de création et de configuration.
- Script Bash d'installation PostgreSQL.
- Documentation du projet.
- Captures d'écran du terminal à ajouter pour illustrer les vérifications et les résultats obtenus.
