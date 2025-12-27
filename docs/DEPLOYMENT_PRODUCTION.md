# Deploy Production su VPS

Guida step-by-step per deployare WordPress in produzione su VPS con Docker.

## Indice

1. [Prerequisiti VPS](#prerequisiti-vps)
2. [Clone repository](#1-clone-repository-sul-vps)
3. [Configurazione environment](#2-configurazione-environment)
4. [Deploy containers](#3-deploy-containers)
5. [Verifica deployment](#4-verifica-deployment)
6. [Accesso WordPress](#5-accesso-wordpress)
7. [Post-deployment checklist](#6-post-deployment-checklist)
8. [Backup automatico](#7-backup-database-setup-automatico)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisiti VPS

### Sistema operativo
- Ubuntu 22.04+ o Debian 11+
- Minimo 1GB RAM (consigliato 2GB+)
- 20GB+ disco SSD

### Software richiesto
- Docker + Docker Compose installati
- Git installato
- UFW firewall configurato

### Caddy Docker Proxy
**PREREQUISITO FONDAMENTALE**: Caddy Docker Proxy deve essere già configurato sul VPS.

Se non l'hai ancora fatto, segui la guida: [CADDY_PROXY_SETUP.md](./CADDY_PROXY_SETUP.md)

Verifica che sia attivo:
```bash
docker ps | grep caddy-proxy
# Deve mostrare il container running

docker network ls | grep caddy
# Deve mostrare il network "caddy"
```

### DNS configurato
Il dominio deve puntare al VPS con un A record:
```
example.com    A    IP_DEL_VPS
```

Verifica:
```bash
dig example.com +short
# Deve mostrare l'IP del tuo VPS
```

### Porte aperte
```bash
sudo ufw status
# 80 e 443 devono essere ALLOW
```

---

## 1. Clone repository sul VPS

```bash
# Connettiti al VPS
ssh user@your-vps.com

# Vai nella directory web
cd /var/www

# Clone del repository
git clone https://github.com/user/frost-theme-custom-plugin.git nome-progetto
cd nome-progetto
```

---

## 2. Configurazione environment

```bash
# Vai nella directory production
cd docker/production

# Copia il template environment
cp .env.example .env

# Modifica il file .env
nano .env
```

### Variabili da modificare OBBLIGATORIAMENTE

```env
# Nome progetto (usato per naming container/volumes)
PROJECT_NAME=nome-cliente

# Dominio (il tuo dominio reale)
DOMAIN=tuodominio.com

# Password database (GENERA PASSWORD FORTI!)
DB_PASSWORD=password_generata_forte
DB_ROOT_PASSWORD=password_root_generata_forte

# Sicurezza WordPress
DISALLOW_FILE_EDIT=true
```

### Genera password sicure

```bash
# Genera password random 32 caratteri
openssl rand -base64 32

# Esempio output: Xk8p2Lm9Qr5Tn1Vw3Yz7Ab4Cd6Ef0Gh==
# Copia e incolla in .env
```

### Esempio .env completo per produzione

```env
PROJECT_NAME=cliente-xyz
DOMAIN=cliente-xyz.com

DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=Xk8p2Lm9Qr5Tn1Vw3Yz7Ab4Cd6Ef0Gh==
DB_ROOT_PASSWORD=Mn3Op5Qr7St9Uv1Wx3Yz5Ab7Cd9Ef1Gh==

TABLE_PREFIX=wp_

WP_MEMORY_LIMIT=256M
WP_MAX_MEMORY_LIMIT=512M
WP_MEMORY_LIMIT_CONTAINER=512M
WP_MEMORY_RESERVATION=256M

DISALLOW_FILE_EDIT=true

MARIADB_BUFFER_POOL=256M
MARIADB_MEMORY_LIMIT=512M
MARIADB_MEMORY_RESERVATION=256M

PHPMYADMIN_PORT=8081
```

---

## 3. Deploy containers

```bash
# Dalla directory docker/production
docker compose up -d
```

Output atteso:
```
[+] Running 3/3
 ✔ Network cliente-xyz-internal  Created
 ✔ Container cliente-xyz-mariadb   Started
 ✔ Container cliente-xyz-wordpress Started
```

---

## 4. Verifica deployment

### Check containers running

```bash
docker compose ps
```

Output atteso:
```
NAME                    STATUS                   PORTS
cliente-xyz-mariadb     Up (healthy)
cliente-xyz-wordpress   Up
```

### Check logs MariaDB

```bash
docker compose logs -f mariadb
# Aspetta messaggio: "ready for connections"
# Premi Ctrl+C per uscire
```

### Check logs WordPress

```bash
docker compose logs -f wordpress
# Aspetta che Apache sia started
# Premi Ctrl+C per uscire
```

### Verifica healthcheck MariaDB

```bash
docker inspect cliente-xyz-mariadb | grep -A 5 Health
```

Output atteso:
```json
"Health": {
    "Status": "healthy",
    ...
}
```

### Verifica network Caddy

```bash
docker network inspect caddy | grep cliente-xyz
# Deve mostrare il container wordpress nel network
```

---

## 5. Accesso WordPress

### Primo accesso

Vai su: `https://tuodominio.com`

Se tutto è configurato correttamente:
1. SSL attivo automaticamente (https)
2. Schermata installazione WordPress

### Installazione WordPress

Compila il form di installazione:

| Campo | Valore consigliato |
|-------|-------------------|
| Titolo sito | Nome del sito |
| Username | **NON usare "admin"** - scegli uno custom |
| Password | Usa la password forte generata |
| Email | Email amministratore reale |

### Login admin

Dopo l'installazione: `https://tuodominio.com/wp-admin`

---

## 6. Post-deployment checklist

### Checklist obbligatoria

- [ ] **SSL attivo** - Verificato https:// funzionante
- [ ] **WordPress accessibile** - Homepage carica
- [ ] **Installazione completata** - Login admin funziona
- [ ] **Permalink settings** - Impostazioni → Permalink → Salva (attiva .htaccess)
- [ ] **DISALLOW_FILE_EDIT verificato** - In Admin non appare "Editor Temi/Plugin"
- [ ] **Frost theme installato** - Aspetto → Temi → Aggiungi → Cerca "Frost"
- [ ] **Child theme attivato** - Attiva frost-child (quando disponibile)
- [ ] **Plugin custom attivato** - Plugin → Attiva (quando disponibile)

### Verifiche sicurezza

```bash
# Verifica che phpMyAdmin NON sia esposto
curl http://tuodominio.com:8081
# Deve fallire (Connection refused)

# Verifica headers sicurezza
curl -I https://tuodominio.com | grep -E 'X-Frame|X-Content|Referrer'
```

### Test SSL completo

- Vai su: https://www.ssllabs.com/ssltest/
- Inserisci il dominio
- Obiettivo: Grade A o A+

---

## 7. Backup database (setup automatico)

### Configura cron per backup giornaliero

```bash
# Apri crontab
crontab -e

# Aggiungi questa riga (backup alle 3:00 AM)
0 3 * * * cd /var/www/nome-progetto && bash docker/scripts/backup-db.sh >> /var/log/wordpress-backup.log 2>&1
```

### Test backup manuale

```bash
cd /var/www/nome-progetto
bash docker/scripts/backup-db.sh
```

Output:
```
🗄️  Starting database backup...
Project: cliente-xyz
Database: wordpress_db
✅ Backup completed: /var/backups/wordpress/cliente-xyz_20241227_150000.sql.gz
Size: 1.2M
🧹 Cleaned up backups older than 30 days
```

### Verifica backup

```bash
ls -lh /var/backups/wordpress/
```

---

## Troubleshooting

### SSL non funziona

#### 1. Verifica DNS

```bash
dig tuodominio.com +short
# Deve mostrare l'IP del VPS
```

Se mostra IP sbagliato o nulla:
- Verifica impostazioni DNS presso il registrar
- Aspetta propagazione (fino a 48h, solitamente minuti)

#### 2. Verifica Caddy logs

```bash
docker logs caddy-proxy --tail 100 | grep -i error
docker logs caddy-proxy --tail 100 | grep tuodominio
```

Errori comuni:
- `ACME challenge failed`: DNS non punta al VPS
- `connection refused`: Container WordPress non running

#### 3. Verifica network

```bash
docker network inspect caddy | grep -A 5 wordpress
# Il container deve essere nel network caddy
```

Se non presente:
```bash
docker compose down
docker compose up -d
```

### WordPress non si connette a MariaDB

#### 1. Verifica healthcheck

```bash
docker inspect nome-progetto-mariadb | grep -A 10 Health
```

Se non healthy:
```bash
docker compose logs mariadb
# Cerca errori specifici
```

#### 2. Verifica credenziali

```bash
# Confronta .env con quello che MariaDB vede
cat .env | grep DB_

# Test connessione manuale
docker exec -it nome-progetto-mariadb \
  mysql -u wordpress_user -p wordpress_db
# Inserisci la password da .env
```

#### 3. Ricrea containers

```bash
docker compose down
docker compose up -d
# Aspetta healthcheck
sleep 60
docker compose ps
```

### Container non partono

#### 1. Verifica risorse

```bash
# Memoria disponibile
free -h

# Spazio disco
df -h
```

Se memoria insufficiente, riduci i limits in .env:
```env
WP_MEMORY_LIMIT_CONTAINER=256M
MARIADB_MEMORY_LIMIT=256M
```

#### 2. Verifica logs dettagliati

```bash
docker compose logs --tail 200
```

#### 3. Rimuovi e ricrea

```bash
docker compose down -v  # ATTENZIONE: cancella i dati!
docker compose up -d
```

### Errore 502 Bad Gateway

1. **WordPress container non running**
   ```bash
   docker compose ps
   # Verifica che wordpress sia Up
   ```

2. **Network non connesso**
   ```bash
   docker network connect caddy nome-progetto-wordpress
   ```

3. **Healthcheck MariaDB fallito**
   ```bash
   docker compose logs mariadb
   # WordPress aspetta che MariaDB sia healthy
   ```

### phpMyAdmin per debug

Se hai bisogno di accedere al database:

```bash
# Sul VPS: avvia phpMyAdmin
docker compose --profile debug up -d

# Dal tuo computer: crea SSH tunnel
ssh -L 8081:localhost:8081 user@vps.com

# Nel browser locale
# http://localhost:8081
```

Quando hai finito:
```bash
# Sul VPS: ferma phpMyAdmin
docker compose --profile debug down
# oppure
docker stop nome-progetto-phpmyadmin
```

---

## Comandi utili quotidiani

### Status

```bash
cd /var/www/nome-progetto/docker/production
docker compose ps
docker compose logs --tail 50
```

### Restart

```bash
docker compose restart
# oppure singolo servizio
docker compose restart wordpress
```

### Update deployment

```bash
cd /var/www/nome-progetto
bash docker/scripts/deploy.sh
```

### Backup manuale

```bash
bash docker/scripts/backup-db.sh
```

### Accesso shell container

```bash
# WordPress
docker exec -it nome-progetto-wordpress bash

# MariaDB
docker exec -it nome-progetto-mariadb bash
```

### WP-CLI

```bash
docker exec -it nome-progetto-wordpress wp --allow-root plugin list
docker exec -it nome-progetto-wordpress wp --allow-root theme list
docker exec -it nome-progetto-wordpress wp --allow-root user list
```

---

## Aggiornamenti WordPress

### Via Admin (consigliato)

1. Backup database prima di aggiornare
2. Admin → Dashboard → Aggiornamenti
3. Aggiorna core, temi, plugin

### Via WP-CLI

```bash
# Backup prima
bash docker/scripts/backup-db.sh

# Aggiorna WordPress core
docker exec -it nome-progetto-wordpress wp --allow-root core update

# Aggiorna plugin
docker exec -it nome-progetto-wordpress wp --allow-root plugin update --all

# Aggiorna temi
docker exec -it nome-progetto-wordpress wp --allow-root theme update --all
```

---

## Risorse

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [MariaDB Docker Image](https://hub.docker.com/_/mariadb)
- [Caddy Docker Proxy](https://github.com/lucaslorentz/caddy-docker-proxy)
