#!/bin/bash

# =============================================
# SCRIPT DI DEPLOY - Production
# =============================================
# Uso: ./deploy.sh
# Esegui dalla root del progetto

set -e  # Esce in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       DEPLOY WORDPRESS PRODUCTION      ${NC}"
echo -e "${YELLOW}========================================${NC}"

# Directory base del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PRODUCTION_DIR="$PROJECT_ROOT/docker/production"

echo -e "\n${GREEN}[1/5]${NC} Cambio directory a production..."
cd "$PRODUCTION_DIR"

# Verifica che esista il file .env
if [ ! -f .env ]; then
    echo -e "${RED}ERRORE: File .env non trovato!${NC}"
    echo -e "Copia .env.example in .env e configura i valori:"
    echo -e "  cp .env.example .env"
    exit 1
fi

echo -e "\n${GREEN}[2/5]${NC} Pull ultime modifiche da Git..."
cd "$PROJECT_ROOT"
git pull origin main

echo -e "\n${GREEN}[3/5]${NC} Ricostruzione container Docker..."
cd "$PRODUCTION_DIR"
docker-compose pull
docker-compose up -d --build --remove-orphans

echo -e "\n${GREEN}[4/5]${NC} Attesa avvio servizi (30 secondi)..."
sleep 30

echo -e "\n${GREEN}[5/5]${NC} Fix permessi file WordPress..."
docker exec wordpress-prod chown -R www-data:www-data /var/www/html/wp-content

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}       DEPLOY COMPLETATO CON SUCCESSO   ${NC}"
echo -e "${GREEN}========================================${NC}"

# Mostra stato container
echo -e "\n${YELLOW}Stato container:${NC}"
docker-compose ps

echo -e "\n${YELLOW}Per vedere i log:${NC}"
echo -e "  docker-compose logs -f"
