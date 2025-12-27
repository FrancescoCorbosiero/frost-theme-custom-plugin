#!/bin/bash
# ============================================
# SCRIPT DI RESTORE DATABASE
# ============================================
# Uso: bash docker/scripts/restore-db.sh /path/to/backup.sql.gz
# Esegui dalla root del progetto
#
# ATTENZIONE: Questo script SOVRASCRIVE il database!
# ============================================

set -e  # Esce in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica parametro backup file
if [ -z "$1" ]; then
    echo -e "${RED}Errore: Path del backup file richiesto${NC}"
    echo ""
    echo "Uso: bash docker/scripts/restore-db.sh /path/to/backup.sql.gz"
    echo ""
    echo "Esempio:"
    echo "  bash docker/scripts/restore-db.sh /var/backups/wordpress/frost-production_20241227_150000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Verifica che il file esista
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Errore: Backup file non trovato: $BACKUP_FILE${NC}"
    exit 1
fi

# Directory base del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PRODUCTION_DIR="$PROJECT_ROOT/docker/production"

# Carica variabili d'ambiente
if [ -f "$PRODUCTION_DIR/.env" ]; then
    source "$PRODUCTION_DIR/.env"
else
    echo -e "${RED}Errore: .env file non trovato in $PRODUCTION_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}   RESTORE DATABASE WORDPRESS              ${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""
echo -e "Project:  ${YELLOW}${PROJECT_NAME}${NC}"
echo -e "Database: ${YELLOW}${DB_NAME}${NC}"
echo -e "Backup:   ${YELLOW}${BACKUP_FILE}${NC}"
echo ""
echo -e "${RED}ATTENZIONE: Questo sovrascrivera' TUTTI i dati del database!${NC}"
echo ""
read -p "Sei sicuro di voler continuare? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Operazione annullata${NC}"
    exit 0
fi

# Verifica che il container MariaDB esista e sia running
if ! docker ps --format '{{.Names}}' | grep -q "${PROJECT_NAME}-mariadb"; then
    echo -e "${RED}Errore: Container ${PROJECT_NAME}-mariadb non trovato o non running${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[1/2]${NC} Ripristino database in corso..."

# Decomprimi e importa
gunzip < "$BACKUP_FILE" | docker exec -i ${PROJECT_NAME}-mariadb \
    mysql -u root -p"${DB_ROOT_PASSWORD}" "${DB_NAME}"

echo -e "${YELLOW}[2/2]${NC} Verifica completata..."

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   RESTORE COMPLETATO!                     ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Prossimi passi consigliati:${NC}"
echo -e "1. Riavvia WordPress: docker compose restart wordpress"
echo -e "2. Svuota cache WordPress (se WP Super Cache o simile)"
echo -e "3. Verifica il sito: https://${DOMAIN}"
