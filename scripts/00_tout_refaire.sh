
#!/usr/bin/env bash
set -euo pipefail

# Se placer dans le dossier du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$PROJECT_DIR/sql"

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

# Ce script doit etre execute avec sudo
if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : executez ce script avec sudo."
    exit 1
fi

echo
echo "[1/3] Suppression de l'ancienne base..."

sudo -u postgres psql -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS bankdb WITH (FORCE);"

echo
echo "[2/3] Suppression des roles du projet..."

for role in analyst support app auditor bank_owner; do
    sudo -u postgres psql -v ON_ERROR_STOP=1 \
        -c "DROP ROLE IF EXISTS $role;"
done

echo
echo "[3/3] Reconstruction de la base et des objets..."

# Creer le role proprietaire et la base
sudo -u postgres psql -v ON_ERROR_STOP=1 \
    -f "$SQL_DIR/00_create_database.sql"

# Executer les scripts SQL numerotes dans l'ordre
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
