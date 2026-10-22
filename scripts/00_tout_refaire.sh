set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )"
SQL_DIR="$PROJECT_DIR/sql"

echo "========================================"
echo " RECONSTRUCTION COMPLETE DE NOVABANK"
echo "========================================"
echo
echo "ATTENTION : cette operation va supprimer"
echo "la base bankdb et reconstruire le projet."
echo "Toutes les données actuelles seront perdues"
echo

read -r -p "Tapez RECONSTRUIRE pour continuer : " confirmation

if [[ "$confirmation" != "RECONSTRUIRE" ]]; then
	echo "Operation annulée."
	exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Erreur : executez ce script avec sudo"
	exit 1;
fi

echo 
echo "[1/3] Suppression de l'ancienne base..."

sudo -u postgres psql -v ON_ERROR_STOP=1 \
	-c "DROP DATABASE IF EXISTS bankdb WITH (FORCE);"
