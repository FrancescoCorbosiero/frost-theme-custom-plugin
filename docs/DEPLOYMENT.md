# Guida al Deploy su VPS

Questa guida spiega come deployare WordPress con Docker su un server VPS.

## Prerequisiti

### Requisiti di Sistema

- **OS**: Ubuntu 20.04+ / Debian 11+ (consigliato)
- **RAM**: Minimo 1GB (consigliato 2GB+)
- **CPU**: 1 vCore minimo
- **Storage**: 20GB+ SSD
- **Porte aperte**: 80, 443, 22 (SSH)

### Software Richiesto

```bash
# Aggiorna il sistema
sudo apt update && sudo apt upgrade -y

# Installa Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Installa Docker Compose
sudo apt install docker-compose -y

# Installa Git
sudo apt install git -y

# Riavvia per applicare i permessi Docker
sudo reboot
```

---

## Deploy Passo-Passo

### 1. Configura il DNS

Prima di iniziare, configura i record DNS del tuo dominio:

| Tipo | Nome | Valore |
|------|------|--------|
| A | @ | IP_DEL_TUO_SERVER |
| A | www | IP_DEL_TUO_SERVER |

> **Nota**: La propagazione DNS può richiedere fino a 24 ore (solitamente 5-30 minuti).

### 2. Clona il Repository

```bash
# Connettiti via SSH
ssh user@tuo-server-ip

# Vai nella directory web
cd /var/www

# Clona il repository
sudo git clone https://github.com/tuouser/frost-theme-custom-plugin.git wordpress
sudo chown -R $USER:$USER wordpress
cd wordpress
```

### 3. Configura l'Ambiente

```bash
# Vai nella directory production
cd docker/production

# Copia il file di configurazione
cp .env.example .env

# Modifica le variabili d'ambiente
nano .env
```

**Variabili da modificare obbligatoriamente:**

```env
DOMAIN=tuodominio.com
WORDPRESS_DB_PASSWORD=password_molto_sicura_123!
MYSQL_ROOT_PASSWORD=altra_password_sicura_456!
```

> **IMPORTANTE**: Usa password forti! Almeno 16 caratteri con lettere, numeri e simboli.

### 4. Configura Caddy (SSL)

```bash
# Modifica il Caddyfile con il tuo dominio
nano Caddyfile
```

Sostituisci `example.com` con il tuo dominio reale:

```caddyfile
tuodominio.com {
    reverse_proxy wordpress:80
    # ... resto della configurazione
}

www.tuodominio.com {
    redir https://tuodominio.com{uri} permanent
}
```

### 5. Esegui il Deploy

```bash
# Rendi eseguibili gli script
chmod +x ../scripts/*.sh

# Primo avvio (senza git pull)
docker-compose up -d

# Attendi l'avvio (circa 30-60 secondi)
sleep 60

# Verifica che i container siano attivi
docker-compose ps
```

### 6. Completa l'Installazione WordPress

1. Apri `https://tuodominio.com` nel browser
2. Seleziona la lingua
3. Inserisci i dati del sito:
   - Titolo sito
   - Username admin
   - Password admin (usa una password forte!)
   - Email admin
4. Clicca "Installa WordPress"

---

## Verifica SSL

Dopo il deploy, verifica che SSL funzioni correttamente:

```bash
# Controlla i log di Caddy
docker logs caddy-prod

# Verifica il certificato
curl -I https://tuodominio.com
```

Dovresti vedere:
- `HTTP/2 200`
- Header `strict-transport-security`

### Test SSL Online

Usa questi strumenti per verificare la configurazione SSL:
- [SSL Labs](https://www.ssllabs.com/ssltest/)
- [Security Headers](https://securityheaders.com/)

---

## Deploy Successivi

Per i deploy successivi (aggiornamenti codice):

```bash
# Dalla root del progetto
cd /var/www/wordpress

# Esegui lo script di deploy
./docker/scripts/deploy.sh
```

Lo script esegue automaticamente:
1. Git pull
2. Ricostruzione container
3. Fix permessi

---

## Backup Database

```bash
# Backup manuale
./docker/scripts/backup-db.sh prod

# I backup vengono salvati in:
# /var/backups/wordpress/
```

### Backup Automatico (Cron)

```bash
# Apri crontab
crontab -e

# Aggiungi backup giornaliero alle 3:00
0 3 * * * /var/www/wordpress/docker/scripts/backup-db.sh prod
```

---

## Comandi Utili

```bash
# Stato container
docker-compose ps

# Log in tempo reale
docker-compose logs -f

# Log specifico container
docker logs -f wordpress-prod
docker logs -f mysql-prod
docker logs -f caddy-prod

# Riavvia tutti i container
docker-compose restart

# Ferma tutto
docker-compose down

# Ferma e rimuovi volumi (ATTENZIONE: cancella dati!)
docker-compose down -v

# Accedi al container WordPress
docker exec -it wordpress-prod bash

# Accedi a MySQL
docker exec -it mysql-prod mysql -u wpuser_prod -p
```

---

## Struttura Directory su VPS

```
/var/www/wordpress/
├── docker/
│   ├── development/     # Non usato in produzione
│   ├── production/
│   │   ├── docker-compose.yml
│   │   ├── Caddyfile
│   │   └── .env
│   └── scripts/
│       ├── deploy.sh
│       ├── backup-db.sh
│       └── restore-db.sh
├── themes/
│   └── frost-child/     # Il tuo child theme
├── plugins/
│   └── agency-custom-blocks/  # Il tuo plugin
└── docs/

/var/backups/wordpress/   # Backup database
```

---

## Prossimi Passi

Dopo il deploy:

1. [ ] Installa e attiva il child theme Frost
2. [ ] Installa e attiva il plugin custom blocks
3. [ ] Configura i permalink (Impostazioni > Permalink)
4. [ ] Installa plugin di sicurezza (Wordfence, etc.)
5. [ ] Configura backup automatici
6. [ ] Monitora i log periodicamente
