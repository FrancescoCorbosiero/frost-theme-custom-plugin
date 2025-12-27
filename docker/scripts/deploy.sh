#!/bin/bash
# ============================================
# SCRIPT DI DEPLOY - Production VPS
# ============================================
# Uso: bash docker/scripts/deploy.sh
# Esegui dalla root del progetto
#
# Questo script:
# 1. Pull delle ultime modifiche da Git
# 2. Verifica esistenza .env
# 3. Deploy containers con Docker Compose
# 4. Verifica deployment
# ============================================

set -e  # Esce in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   DEPLOY WORDPRESS PRODUCTION             ${NC}"
echo -e "${GREEN}============================================${NC}"

# Directory base del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PRODUCTION_DIR="$PROJECT_ROOT/docker/production"

echo ""
echo -e "${YELLOW}[1/5]${NC} Pull ultime modifiche da Git..."
cd "$PROJECT_ROOT"
git pull origin main

echo ""
echo -e "${YELLOW}[2/5]${NC} Verifica configurazione..."
cd "$PRODUCTION_DIR"

# Verifica che esista il file .env
if [ ! -f .env ]; then
    echo -e "${RED}Errore: .env file non trovato!${NC}"
    echo -e "Copia .env.example in .env e configura i valori:"
    echo -e "  cp .env.example .env"
    echo -e "  nano .env"
    exit 1
fi

# Carica variabili per output
source .env

echo -e "  Project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "  Domain:  ${GREEN}${DOMAIN}${NC}"

echo ""
echo -e "${YELLOW}[3/5]${NC} Deploy containers..."
docker compose up -d --build

echo ""
echo -e "${YELLOW}[4/5]${NC} Attesa healthcheck MariaDB..."
echo -e "  (questo puo' richiedere fino a 60 secondi)"

# Aspetta che MariaDB sia healthy
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' ${PROJECT_NAME}-mariadb 2>/dev/null || echo "starting")
    if [ "$HEALTH" == "healthy" ]; then
        echo -e "  ${GREEN}MariaDB healthy!${NC}"
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -e "  Waiting... ($WAITED/$MAX_WAIT sec)"
done

if [ "$HEALTH" != "healthy" ]; then
    echo -e "${YELLOW}Warning: MariaDB healthcheck timeout${NC}"
    echo -e "Controlla i logs: docker compose logs mariadb"
fi

echo ""
echo -e "${YELLOW}[5/5]${NC} Verifica deployment..."
docker compose ps

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   DEPLOY COMPLETATO!                      ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Sito: ${GREEN}https://${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Comandi utili:${NC}"
echo -e "  Logs:      docker compose logs -f"
echo -e "  Status:    docker compose ps"
echo -e "  Restart:   docker compose restart"
echo -e "  Backup:    bash docker/scripts/backup-db.sh"
