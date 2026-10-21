#!/usr/bin/env bash
set -euo pipefail

# Vérifier les privilèges
if [[ "$EUID" -ne 0 ]]; then
	echo "Erreur : exécutez ce script avec sudo."
	exit 1
fi

echo "[1/5] Mise à jour des paquets..."
apt-get update

echo "[2/5] Installation de PostgreSQL 18, du client et d'UFW..."
apt-get install -y postgresql-18 postgresql-client-18 ufw

echo "[3/5] Configuration de PostgreSQL..."
CONF_DIR="/etc/postgresql/18/main/conf.d"
CONF_FILE="$CONF_DIR/novabank.conf"

mkdir -p "$CONF_DIR"

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

cat > "$TEMP_FILE" <<'EOF'
listen_addresses = 'localhost,192.168.56.10'
password_encryption = scram-sha-256
log_connections = on
log_statement = 'ddl'
EOF

if [[ ! -f "$CONF_FILE" ]] || ! cmp -s "$TEMP_FILE" "$CONF_FILE"; then
	if [[ -f "$CONF_FILE" ]]; then
		cp "$CONF_FILE" "$CONF_FILE.bak"
		echo "Sauvegarde de la configuration existante effectuée."
	fi

	install -m 644 "$TEMP_FILE" "$CONF_FILE"
	echo "Configuration PostgreSQL mise à jour"
else
	echo "Configuration PostgreSQL déjà mise à jour."
fi

rm -f "$TEMP_FILE"
trap - EXIT

echo "[4/5] Configuration du pare-feu..."
ufw allow OpenSSH
ufw allow from 192.168.56.1 to 192.168.56.10 port 5432 proto tcp

if ! ufw status | grep -q "^Status: active"; then
	ufw --force enable
fi

echo "[5/5] Démarrage et redémarrage de PostgreSQL..."
systemctl enable --now postgresql
systemctl restart postgresql

echo "Vérification du cluster PostgreSQL :"
pg_lsclusters

echo "Installation et configuration terminées."

