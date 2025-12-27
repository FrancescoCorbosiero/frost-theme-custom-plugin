# Frost Theme + Custom Plugin Boilerplate

> **WordPress agency starter kit** - Boilerplate riutilizzabile basato su Frost theme + FSE + Custom Gutenberg Blocks

## 🎯 Obiettivo

Questo repository è un **BOILERPLATE GENERICO** per progetti WordPress agency/freelancer.

**Non è un progetto specifico** → È un template da forkare per ogni nuovo cliente.

### Filosofia del boilerplate

- ✅ **Generico e riutilizzabile** - Fork per ogni progetto
- ✅ **Infrastruttura-first** - Docker + VPS ready
- ✅ **Design system variabile** - Customizza colori/font facilmente
- ✅ **Blocchi placeholder** - Contenuto generico sostituibile
- ✅ **Zero dipendenze esterne** - No page builders, no build tools
- ✅ **Documentazione inline** - Commenti su dove customizzare

## 📦 Cosa contiene questo boilerplate

### Fase 1: Infrastruttura VPS (QUESTO STEP)
- ✅ Docker Compose per development e production
- ✅ Setup WordPress + MySQL + phpMyAdmin
- ✅ Bind mounts per hot reload (no named volumes)
- ✅ Caddy reverse proxy ready (SSL automatico)
- ✅ Environment variables per multi-progetti
- ✅ Script deployment e backup

### Fase 2: Child Theme Frost (PROSSIMO STEP)
- ⏳ `theme.json` con design system neutro
- ⏳ Pattern riutilizzabili (hero, CTA, footer, testimonial)
- ⏳ Template generici (full-width, bio-link)
- ⏳ Functions.php con utility commentate

### Fase 3: Plugin Custom Blocks (ULTIMO STEP)
- ⏳ Blocchi generici server-rendered (card, testimonial, CTA, grid)
- ⏳ Attributi placeholder configurabili
- ⏳ CSS modulare facilmente customizzabile

## 🏗️ Architettura Infrastruttura

### Development Environment

```
┌─────────────────────────────────────────┐
│   Localhost:8080 (WordPress)            │
│   ├── themes/frost-child/               │
│   └── plugins/agency-custom-blocks/     │
├─────────────────────────────────────────┤
│   Localhost:8081 (phpMyAdmin)           │
├─────────────────────────────────────────┤
│   MySQL:3306 (Database)                 │
└─────────────────────────────────────────┘
```

**Caratteristiche:**
- Bind mounts diretti (modifiche immediate)
- Hot reload automatico (no rebuild)
- Database persistente in volume Docker
- WP-CLI incluso nel container

### Production Environment (VPS)

```
Internet
    ↓
Caddy Reverse Proxy (SSL automatico)
    ↓ :443 → :80
WordPress Container (frost-child + plugin)
    ↓
MySQL Container (db persistente)
```

**Caratteristiche:**
- SSL automatico via Let's Encrypt (Caddy)
- Reverse proxy con domini multipli
- Database backup automatico
- Deploy via Git + Docker Compose

## 📁 Struttura del Repository

```
frost-theme-custom-plugin/
│
├── docker/
│   ├── development/
│   │   ├── docker-compose.yml        # Config dev
│   │   └── .env.example              # Template env dev
│   │
│   ├── production/
│   │   ├── docker-compose.yml        # Config prod (no phpMyAdmin)
│   │   ├── .env.example              # Template env prod
│   │   └── Caddyfile                 # Reverse proxy config
│   │
│   └── scripts/
│       ├── deploy.sh                 # Script deploy su VPS
│       ├── backup-db.sh              # Backup database
│       └── restore-db.sh             # Restore database
│
├── themes/
│   └── frost-child/                  # [FASE 2]
│       ├── theme.json
│       ├── style.css
│       ├── functions.php
│       ├── patterns/
│       └── templates/
│
├── plugins/
│   └── agency-custom-blocks/         # [FASE 3]
│       ├── agency-custom-blocks.php
│       ├── blocks/
│       └── inc/
│
├── docs/
│   ├── CUSTOMIZATION.md              # Guida fork per nuovi progetti
│   ├── DEPLOYMENT.md                 # Guida deploy VPS
│   └── TROUBLESHOOTING.md            # Common issues
│
├── .gitignore
├── CLAUDE_CODE_PROMPT.txt            # Prompt per generazione automatica
└── README.md                         # Questo file
```

## 🚀 Quick Start - Development

### 1. Clone del repository

```bash
git clone https://github.com/FrancescoCorbosiero/frost-theme-custom-plugin.git
cd frost-theme-custom-plugin
```

### 2. Setup environment development

```bash
cd docker/development
cp .env.example .env

# Modifica .env se necessario (opzionale)
nano .env
```

### 3. Avvia Docker Compose

```bash
docker-compose up -d
```

### 4. Aspetta che WordPress sia pronto

```bash
# Controlla i log
docker-compose logs -f wordpress

# Aspetta messaggio: "WordPress is ready"
```

### 5. Accedi a WordPress

- **Frontend**: http://localhost:8080
- **Admin**: http://localhost:8080/wp-admin
  - User: `admin`
  - Password: `admin` (cambia in `.env` per sicurezza)
- **phpMyAdmin**: http://localhost:8081
  - Server: `db`
  - User: vedi `.env`

### 6. Installa Frost parent theme

```bash
# Opzione A: da wp-admin
# Appearance → Themes → Add New → Search "Frost" → Install

# Opzione B: via WP-CLI
docker exec -it wordpress-dev wp theme install frost --activate
```

### 7. Attiva child theme e plugin (quando creati in Fase 2 e 3)

```bash
# Child theme
docker exec -it wordpress-dev wp theme activate frost-child

# Plugin
docker exec -it wordpress-dev wp plugin activate agency-custom-blocks
```

## 🌐 Production Deployment (VPS)

### Architettura Production

- **Caddy Docker Proxy** esterno (SSL automatico, multi-sito)
- **MariaDB 11.4-lts** (supporto fino 2029)
- **WordPress 6-php8.3-apache** (PHP 8.3 supporto fino 2027)
- **Resource limits** e healthchecks
- **Named volumes** con isolamento per progetto
- **phpMyAdmin opzionale** per debug (SSH tunnel)

### Quick Start Production

#### Prerequisiti

1. VPS con Docker + Docker Compose
2. Caddy Docker Proxy installato (vedi `docs/CADDY_PROXY_SETUP.md`)
3. Dominio con DNS puntato al VPS

#### Deploy

```bash
# 1. Clone sul VPS
ssh user@vps.com
cd /var/www
git clone <repo> nome-progetto
cd nome-progetto

# 2. Configure
cd docker/production
cp .env.example .env
nano .env  # Modifica PROJECT_NAME, DOMAIN, passwords

# 3. Deploy
docker compose up -d

# 4. Verifica
docker compose logs -f
# Vai su https://tuo-dominio.com
```

#### Comandi utili

```bash
# Deploy updates
bash docker/scripts/deploy.sh

# Backup database
bash docker/scripts/backup-db.sh

# Restore database
bash docker/scripts/restore-db.sh /path/to/backup.sql.gz

# phpMyAdmin (debug via SSH tunnel)
docker compose --profile debug up -d
ssh -L 8081:localhost:8081 user@vps.com
# Accedi: http://localhost:8081
```

### Differenze Development vs Production

| Feature | Development | Production |
|---------|------------|------------|
| Database | MySQL 8.0 | MariaDB 11.4-lts |
| Networking | Bridge network locale | Caddy network esterno |
| Volumes | Bind mounts (hot reload) | Named volumes |
| phpMyAdmin | Sempre attivo :8081 | Opzionale (SSH tunnel) |
| SSL | No (localhost) | Automatico (Let's Encrypt) |
| Resource limits | No | Si (configurabili) |
| Healthchecks | No | Si (MariaDB) |
| File editing | Abilitato | Disabilitato (security) |

Vedi documentazione completa:
- `docs/CADDY_PROXY_SETUP.md` - Setup Caddy Proxy
- `docs/DEPLOYMENT_PRODUCTION.md` - Guida deploy VPS

## 🔧 Comandi Utili

### Development

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# Restart WordPress
docker-compose restart wordpress

# View logs
docker-compose logs -f wordpress

# Access WordPress container shell
docker exec -it wordpress-dev bash

# WP-CLI commands
docker exec -it wordpress-dev wp plugin list
docker exec -it wordpress-dev wp theme list
docker exec -it wordpress-dev wp user list
```

### Production

```bash
# Deploy updates
cd /var/www/your-project-name
git pull origin main
docker-compose -f docker/production/docker-compose.yml up -d --build

# Backup database
bash docker/scripts/backup-db.sh

# View Caddy logs (SSL issues)
docker-compose logs -f caddy
```

## 📊 Environment Variables

### `.env` Development

```env
# Database Configuration
WORDPRESS_DB_NAME=wordpress_dev
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=wppass
MYSQL_ROOT_PASSWORD=rootpass

# WordPress Configuration
WORDPRESS_TABLE_PREFIX=wp_
WORDPRESS_DEBUG=true

# Container Names
COMPOSE_PROJECT_NAME=frost-dev
```

### `.env` Production

```env
# Database Configuration (USA PASSWORD FORTI!)
WORDPRESS_DB_NAME=produzione_db
WORDPRESS_DB_USER=wpuser_prod
WORDPRESS_DB_PASSWORD=GENERA_PASSWORD_SICURA
MYSQL_ROOT_PASSWORD=GENERA_PASSWORD_SICURA

# WordPress Configuration
WORDPRESS_TABLE_PREFIX=wp_
WORDPRESS_DEBUG=false

# Domain
DOMAIN=tuodominio.com

# Backup
BACKUP_DIR=/var/backups/wordpress
```

## 🔐 Security Best Practices

### Development
- ✅ `.env` in `.gitignore` (mai committare password)
- ✅ Usa localhost solo per dev
- ✅ Cambia password di default in `.env`

### Production
- ✅ Password database complesse (20+ chars, random)
- ✅ WordPress debug = false
- ✅ Firewall UFW attivo (solo 80, 443, 22)
- ✅ Backup database giornalieri automatici
- ✅ SSL automatico via Caddy
- ✅ Aggiorna WordPress/plugin regolarmente

## 🗂️ File Importanti

### `docker/development/docker-compose.yml`
Docker Compose per ambiente di sviluppo locale.

**Servizi:**
- `wordpress`: WordPress latest con bind mounts
- `db`: MySQL 8.0 con volume persistente
- `phpmyadmin`: GUI database su porta 8081

### `docker/production/docker-compose.yml`
Docker Compose per VPS production.

**Servizi:**
- `wordpress`: WordPress latest (no bind mounts, solo volumes)
- `db`: MySQL 8.0 production-ready
- `caddy`: Reverse proxy con SSL automatico

**Differenze vs development:**
- ❌ No phpMyAdmin (sicurezza)
- ✅ Volume WordPress separato (no bind mount)
- ✅ Caddy per SSL e reverse proxy
- ✅ Restart policies (always)

### `docker/production/Caddyfile`
Configurazione Caddy per reverse proxy e SSL.

**Personalizza per ogni progetto:**
```caddyfile
tuodominio.com {
    reverse_proxy wordpress:80
    encode gzip
    
    # Optional: Security headers
    header {
        Strict-Transport-Security "max-age=31536000;"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}
```

## 📖 Prossimi Step

### ✅ Fase 1: Infrastruttura (COMPLETA)
Hai tutto il necessario per:
- Development locale con Docker
- Deploy production su VPS
- Hot reload per sviluppo rapido
- SSL automatico in produzione

### ⏳ Fase 2: Child Theme Frost
Prossima generazione:
- `theme.json` con design system neutro
- Pattern riutilizzabili
- Template base
- Guida customizzazione

### ⏳ Fase 3: Plugin Custom Blocks
Ultima generazione:
- Blocchi generici riutilizzabili
- Server-side rendering
- CSS modulare
- Documentazione attributi

## 🤝 Come Usare Questo Boilerplate

### Per ogni nuovo progetto cliente:

1. **Fork il repository**
   ```bash
   git clone https://github.com/FrancescoCorbosiero/frost-theme-custom-plugin.git cliente-xyz
   cd cliente-xyz
   rm -rf .git
   git init
   ```

2. **Setup development**
   ```bash
   cd docker/development
   cp .env.example .env
   # Modifica COMPOSE_PROJECT_NAME=cliente-xyz
   docker-compose up -d
   ```

3. **Customizza tema e blocchi** (Fase 2 e 3)
   - Modifica `theme.json` (colori, font)
   - Rinomina blocchi per progetto specifico
   - Aggiungi pattern custom

4. **Deploy su VPS cliente**
   ```bash
   # Sul VPS
   cd /var/www
   git clone <repo-cliente-xyz> cliente-xyz
   cd cliente-xyz/docker/production
   cp .env.example .env
   # Configura .env + Caddyfile
   docker-compose up -d
   ```

## 📚 Risorse

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [Frost Theme](https://frostwp.com/)

## 🐛 Troubleshooting

Vedi `docs/TROUBLESHOOTING.md` per problemi comuni.

**Quick fixes:**

```bash
# Container non parte
docker-compose down -v
docker-compose up -d

# Permessi file
docker exec -it wordpress-dev chown -R www-data:www-data /var/www/html

# Cache Caddy
docker exec -it caddy caddy reload --config /etc/caddy/Caddyfile
```

## 📄 License

GPL v2 or later (compatibile con WordPress)

---

**Boilerplate creato per sviluppo WordPress moderno** ⚡  
**Zero page builders | Zero complessità | Massima riusabilità**