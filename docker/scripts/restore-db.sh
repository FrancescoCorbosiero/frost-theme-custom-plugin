#!/bin/bash

# =============================================
# SCRIPT DI RESTORE DATABASE
# =============================================
# Uso: ./restore-db.sh [dev|prod] [path/to/backup.sql.gz]
# Esempio: ./restore-db.sh prod /var/backups/wordpress/backup.sql.gz

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verifica parametri
if [ $# -lt 2 ]; then
    echo -e "${RED}ERRORE: Parametri mancanti!${NC}"
    echo -e "Uso: ./restore-db.sh [dev|prod] [path/to/backup.sql.gz]"
    echo -e "Esempio: ./restore-db.sh prod /var/backups/wordpress/backup.sql.gz"
    exit 1
fi

ENV="$1"
BACKUP_FILE="$2"

# Verifica che il file di backup esista
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}ERRORE: File di backup non trovato: $BACKUP_FILE${NC}"
    exit 1
fi

# Configurazione in base all'ambiente
if [ "$ENV" == "dev" ]; then
    CONTAINER_NAME="mysql-dev"
    ENV_FILE="docker/development/.env"
elif [ "$ENV" == "prod" ]; then
    CONTAINER_NAME="mysql-prod"
    ENV_FILE="docker/production/.env"
else
    echo -e "${RED}ERRORE: Ambiente non valido. Usa 'dev' o 'prod'${NC}"
    exit 1
fi

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       RESTORE DATABASE WORDPRESS       ${NC}"
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

echo -e "\n${YELLOW}ATTENZIONE: Questo sovrascriverà TUTTI i dati del database!${NC}"
echo -e "Database: ${WORDPRESS_DB_NAME}"
echo -e "Backup: ${BACKUP_FILE}"
echo -e ""
read -p "Sei sicuro di voler continuare? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${YELLOW}Operazione annullata.${NC}"
    exit 0
fi

echo -e "\n${GREEN}[1/3]${NC} Decompressione backup..."

# Determina se il file è compresso
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "File compresso, decompressione in corso..."
    TEMP_SQL="/tmp/restore_$(date +%s).sql"
    gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
    SQL_FILE="$TEMP_SQL"
    CLEANUP_TEMP=true
else
    SQL_FILE="$BACKUP_FILE"
    CLEANUP_TEMP=false
fi

echo -e "\n${GREEN}[2/3]${NC} Importazione database..."
echo -e "Container: ${CONTAINER_NAME}"

# Esegui l'import
cat "$SQL_FILE" | docker exec -i "$CONTAINER_NAME" mysql \
    -u"$WORDPRESS_DB_USER" \
    -p"$WORDPRESS_DB_PASSWORD" \
    "$WORDPRESS_DB_NAME"

echo -e "\n${GREEN}[3/3]${NC} Pulizia file temporanei..."

# Rimuovi file temporaneo se creato
if [ "$CLEANUP_TEMP" = true ] && [ -f "$TEMP_SQL" ]; then
    rm "$TEMP_SQL"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}       RESTORE COMPLETATO!              ${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Nota: Potrebbe essere necessario svuotare la cache di WordPress.${NC}"
