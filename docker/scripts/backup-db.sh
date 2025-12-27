#!/bin/bash
# ============================================
# SCRIPT DI BACKUP DATABASE
# ============================================
# Uso: bash docker/scripts/backup-db.sh
# Esegui dalla root del progetto
#
# Questo script:
# 1. Dump del database MariaDB
# 2. Compressione con gzip
# 3. Salvataggio in BACKUP_DIR
# 4. Pulizia backup > 30 giorni
# ============================================

set -e  # Esce in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Directory backup (default se non specificata)
BACKUP_DIR="${BACKUP_DIR:-/var/backups/wordpress}"

# Crea directory backup se non esiste
mkdir -p "$BACKUP_DIR"

# Filename con timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${PROJECT_NAME}_${TIMESTAMP}.sql.gz"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   BACKUP DATABASE WORDPRESS               ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Project:  ${YELLOW}${PROJECT_NAME}${NC}"
echo -e "Database: ${YELLOW}${DB_NAME}${NC}"
echo -e "Output:   ${YELLOW}${BACKUP_FILE}${NC}"
echo ""

# Verifica che il container MariaDB esista e sia running
if ! docker ps --format '{{.Names}}' | grep -q "${PROJECT_NAME}-mariadb"; then
    echo -e "${RED}Errore: Container ${PROJECT_NAME}-mariadb non trovato o non running${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/3]${NC} Esecuzione dump database..."

# Dump database con compressione
docker exec ${PROJECT_NAME}-mariadb \
    mysqldump -u root -p"${DB_ROOT_PASSWORD}" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    "${DB_NAME}" | gzip > "$BACKUP_FILE"

echo -e "${YELLOW}[2/3]${NC} Verifica backup..."

# Verifica che il file esista e non sia vuoto
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "  ${GREEN}Backup completato!${NC}"
    echo -e "  Size: ${GREEN}${FILE_SIZE}${NC}"
else
    echo -e "${RED}Errore: Backup fallito - file vuoto o non creato${NC}"
    exit 1
fi

echo -e "${YELLOW}[3/3]${NC} Pulizia backup vecchi..."

# Conta backup prima della pulizia
OLD_COUNT=$(find "$BACKUP_DIR" -name "${PROJECT_NAME}_*.sql.gz" -mtime +30 | wc -l)

# Rimuovi backup piu vecchi di 30 giorni
find "$BACKUP_DIR" -name "${PROJECT_NAME}_*.sql.gz" -mtime +30 -delete

echo -e "  Rimossi ${OLD_COUNT} backup > 30 giorni"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   BACKUP COMPLETATO!                      ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "File: ${GREEN}${BACKUP_FILE}${NC}"
echo -e "Size: ${GREEN}${FILE_SIZE}${NC}"
echo ""
echo -e "${YELLOW}Per ripristinare:${NC}"
echo -e "  bash docker/scripts/restore-db.sh ${BACKUP_FILE}"
echo ""

# Lista ultimi 5 backup
echo -e "${YELLOW}Ultimi 5 backup:${NC}"
ls -lht "$BACKUP_DIR"/${PROJECT_NAME}_*.sql.gz 2>/dev/null | head -5
