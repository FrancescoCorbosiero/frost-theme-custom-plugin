#!/bin/bash

# =============================================
# SCRIPT DI BACKUP DATABASE
# =============================================
# Uso: ./backup-db.sh [dev|prod]
# Default: prod

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parametro ambiente (default: prod)
ENV="${1:-prod}"

# Directory backup
BACKUP_DIR="/var/backups/wordpress"

# Timestamp per nome file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Configurazione in base all'ambiente
if [ "$ENV" == "dev" ]; then
    CONTAINER_NAME="mysql-dev"
    ENV_FILE="docker/development/.env"
    BACKUP_PREFIX="dev"
elif [ "$ENV" == "prod" ]; then
    CONTAINER_NAME="mysql-prod"
    ENV_FILE="docker/production/.env"
    BACKUP_PREFIX="prod"
else
    echo -e "${RED}ERRORE: Ambiente non valido. Usa 'dev' o 'prod'${NC}"
    exit 1
fi

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       BACKUP DATABASE WORDPRESS        ${NC}"
echo -e "${YELLOW}       Ambiente: ${ENV}                 ${NC}"
echo -e "${YELLOW}========================================${NC}"

# Trova la root del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Carica variabili d'ambiente
if [ -f "$PROJECT_ROOT/$ENV_FILE" ]; then
    source "$PROJECT_ROOT/$ENV_FILE"
else
    echo -e "${RED}ERRORE: File $ENV_FILE non trovato!${NC}"
    exit 1
fi

# Crea directory backup se non esiste
echo -e "\n${GREEN}[1/3]${NC} Creazione directory backup..."
sudo mkdir -p "$BACKUP_DIR"
sudo chown $(whoami):$(whoami) "$BACKUP_DIR"

# Nome file backup
BACKUP_FILE="${BACKUP_DIR}/wordpress_${BACKUP_PREFIX}_${TIMESTAMP}.sql.gz"

echo -e "\n${GREEN}[2/3]${NC} Esecuzione backup database..."
echo -e "Container: ${CONTAINER_NAME}"
echo -e "Database: ${WORDPRESS_DB_NAME}"

# Esegui mysqldump e comprimi
docker exec "$CONTAINER_NAME" mysqldump \
    -u"$WORDPRESS_DB_USER" \
    -p"$WORDPRESS_DB_PASSWORD" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    "$WORDPRESS_DB_NAME" | gzip > "$BACKUP_FILE"

echo -e "\n${GREEN}[3/3]${NC} Verifica backup..."

# Verifica che il file esista e non sia vuoto
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       BACKUP COMPLETATO!               ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\nFile: ${BACKUP_FILE}"
    echo -e "Dimensione: ${FILE_SIZE}"
    echo -e "\nPer ripristinare usa:"
    echo -e "  ./restore-db.sh ${ENV} ${BACKUP_FILE}"
else
    echo -e "${RED}ERRORE: Backup fallito!${NC}"
    exit 1
fi

# Lista ultimi 5 backup
echo -e "\n${YELLOW}Ultimi 5 backup:${NC}"
ls -lht "$BACKUP_DIR" | head -6
