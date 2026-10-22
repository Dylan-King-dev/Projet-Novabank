#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$PROJECT_DIR/sql"

if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : executez ce script avec sudo."
    exit 1
fi

for numero in $(seq -w 0 15); do
    fichier="$SQL_DIR/${numero}_"

    case "$numero" in
        00) nom="create_database.sql" ;;
        01) nom="create_schemas.sql" ;;
        02) nom="create_tables.sql" ;;
        03) nom="seed_data.sql" ;;
        04) nom="create_roles.sql" ;;
        05) nom="grant_permissions.sql" ;;
        06) nom="create_views.sql" ;;
        07) nom="create_updatable_view.sql" ;;
        08) nom="create_materialized_view.sql" ;;
        09) nom="create_indexes.sql" ;;
        10) nom="audit_trigger.sql" ;;
        11) nom="attach_audit_triggers.sql" ;;
        12) nom="protect_ledger.sql" ;;
        13) nom="fraud_alert_trigger.sql" ;;
        14) nom="balance_trigger.sql" ;;
        15) nom="create_procedures.sql" ;;
    esac

    if [[ ! -f "$fichier$nom" ]]; then
        echo "Erreur : script manquant : $fichier$nom"
        exit 1
    fi
done

echo "========================================"
echo " RECONSTRUCTION COMPLETE DE NOVABANK"
echo "========================================"
echo
echo "ATTENTION : cette operation va supprimer"
echo "la base bankdb et reconstruire le projet."
echo "Toutes les donnees actuelles seront perdues."
echo

read -r -p "Tapez RECONSTRUIRE pour continuer : " confirmation

if [[ "$confirmation" != "RECONSTRUIRE" ]]; then
    echo "Operation annulee."
    exit 0
fi

echo
echo "[1/3] Suppression de l'ancienne base..."

sudo -u postgres psql -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS bankdb WITH (FORCE);"

echo
echo "[2/3] Suppression des roles du projet..."

for role in analyst_user support_user app_user auditor_user analyst support app auditor bank_owner; do
    sudo -u postgres psql -v ON_ERROR_STOP=1 \
        -c "DROP ROLE IF EXISTS $role;"
done

echo
echo "[3/3] Reconstruction de la base et des objets..."

sudo -u postgres psql -v ON_ERROR_STOP=1 \
    -f "$SQL_DIR/00_create_database.sql"

for fichier in "$SQL_DIR"/[0-9][0-9]_*.sql; do
    if [[ "$fichier" == "$SQL_DIR/00_"* ]]; then
        continue
    fi

    echo
    echo "Execution : $(basename "$fichier")"

    sudo -u postgres psql \
        -v ON_ERROR_STOP=1 \
        -d bankdb \
        -f "$fichier"
done

echo
echo "Reconstruction terminee avec succes."
