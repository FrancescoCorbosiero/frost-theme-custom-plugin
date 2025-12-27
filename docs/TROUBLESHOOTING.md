# Troubleshooting - Problemi Comuni

Guida alla risoluzione dei problemi più comuni con Docker e WordPress.

---

## Problemi Docker

### Container non parte

**Sintomo**: `docker-compose up` fallisce o container in stato "Exited"

**Diagnosi**:
```bash
# Controlla lo stato
docker-compose ps

# Leggi i log del container problematico
docker logs wordpress-dev  # o wordpress-prod
docker logs mysql-dev      # o mysql-prod
```

**Soluzioni comuni**:

1. **Porta già in uso**:
```bash
# Trova cosa usa la porta 8080
sudo lsof -i :8080

# Termina il processo o cambia porta in docker-compose.yml
```

2. **Memoria insufficiente**:
```bash
# Controlla memoria disponibile
free -h

# Libera memoria Docker
docker system prune -a
```

3. **Permessi Docker**:
```bash
# Aggiungi utente al gruppo docker
sudo usermod -aG docker $USER
# Rilogga o riavvia
```

---

### Container si riavvia continuamente

**Sintomo**: Container in loop di restart

**Diagnosi**:
```bash
docker logs --tail 100 container-name
```

**Soluzioni**:

1. **Errore MySQL "Access denied"**:
   - Verifica che le password in `.env` siano corrette
   - Elimina il volume MySQL e ricrea:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

2. **WordPress non trova il database**:
   - Attendi che MySQL sia pronto (può richiedere 30-60 sec)
   - Verifica la connessione:
   ```bash
   docker exec mysql-dev mysql -u wpuser -pwppass -e "SHOW DATABASES;"
   ```

---

## Problemi Permessi File

### Errore "Permission denied" su WordPress

**Sintomo**: Impossibile caricare file, installare plugin, aggiornare

**Soluzione Development**:
```bash
# Correggi permessi cartelle montate
sudo chown -R $(whoami):$(whoami) themes/ plugins/
chmod -R 755 themes/ plugins/
```

**Soluzione Production**:
```bash
# Correggi permessi dentro il container
docker exec wordpress-prod chown -R www-data:www-data /var/www/html/wp-content
docker exec wordpress-prod chmod -R 755 /var/www/html/wp-content
```

### Bind mounts non funzionano (Development)

**Sintomo**: Modifiche ai file non visibili in WordPress

**Verifica**:
```bash
# Controlla che la cartella sia montata
docker exec wordpress-dev ls -la /var/www/html/wp-content/themes/

# Verifica i path nel docker-compose.yml
cat docker/development/docker-compose.yml | grep volumes -A 5
```

**Soluzioni**:

1. **Path errato**: I path devono essere relativi a dove si trova docker-compose.yml
   ```yaml
   # Corretto (da docker/development/)
   ./../../themes/frost-child:/var/www/html/wp-content/themes/frost-child
   ```

2. **Cartella non esiste**: Crea la cartella se manca
   ```bash
   mkdir -p themes/frost-child
   ```

3. **Docker Desktop (Mac/Windows)**: Verifica che la cartella sia condivisa in Docker Desktop > Settings > Resources > File Sharing

---

## Problemi Database

### Reset completo database

**ATTENZIONE**: Questo cancella TUTTI i dati!

```bash
cd docker/development  # o docker/production

# Ferma e rimuovi volumi
docker-compose down -v

# Riavvia (database vuoto)
docker-compose up -d
```

### Errore connessione database

**Sintomo**: "Error establishing a database connection"

**Diagnosi**:
```bash
# Verifica che MySQL sia attivo
docker-compose ps

# Test connessione
docker exec mysql-dev mysql -u wpuser -pwppass -e "SELECT 1;"
```

**Soluzioni**:

1. **MySQL non ancora pronto**: Attendi 30-60 secondi dopo l'avvio
2. **Credenziali errate**: Confronta `.env` con `docker-compose.yml`
3. **Database non esiste**:
   ```bash
   docker exec mysql-dev mysql -u root -prootpass -e "CREATE DATABASE IF NOT EXISTS wordpress_dev;"
   ```

### Import/Export database

```bash
# Export
docker exec mysql-dev mysqldump -u wpuser -pwppass wordpress_dev > backup.sql

# Import
cat backup.sql | docker exec -i mysql-dev mysql -u wpuser -pwppass wordpress_dev
```

---

## Problemi SSL (Caddy)

### SSL non funziona

**Sintomo**: Sito non raggiungibile su HTTPS o errore certificato

**Diagnosi**:
```bash
# Log di Caddy
docker logs caddy-prod

# Verifica certificati
docker exec caddy-prod ls -la /data/caddy/certificates/
```

**Soluzioni**:

1. **DNS non configurato**:
   ```bash
   # Verifica DNS
   nslookup tuodominio.com
   dig tuodominio.com
   ```
   Il dominio deve puntare all'IP del server.

2. **Porte 80/443 bloccate**:
   ```bash
   # Verifica porte
   sudo ufw status

   # Apri porte se necessario
   sudo ufw allow 80
   sudo ufw allow 443
   ```

3. **Troppi tentativi (rate limit Let's Encrypt)**:
   - Attendi 1 ora
   - Usa staging per test: aggiungi `tls internal` nel Caddyfile

4. **Dominio errato nel Caddyfile**:
   ```bash
   # Verifica configurazione
   cat docker/production/Caddyfile

   # Modifica e riavvia
   nano docker/production/Caddyfile
   docker-compose restart caddy
   ```

### Redirect loop HTTPS

**Sintomo**: "Too many redirects"

**Soluzione**: Aggiungi in wp-config.php (dentro il container):
```php
define('FORCE_SSL_ADMIN', true);
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

```bash
docker exec -it wordpress-prod nano /var/www/html/wp-config.php
```

---

## Problemi Comuni WordPress

### White screen of death

```bash
# Abilita debug
docker exec wordpress-prod bash -c "echo \"define('WP_DEBUG', true);\" >> /var/www/html/wp-config.php"
docker exec wordpress-prod bash -c "echo \"define('WP_DEBUG_LOG', true);\" >> /var/www/html/wp-config.php"

# Leggi log errori
docker exec wordpress-prod cat /var/www/html/wp-content/debug.log
```

### Errore memoria PHP

```bash
# Aumenta memoria in wp-config.php
docker exec wordpress-prod bash -c "echo \"define('WP_MEMORY_LIMIT', '256M');\" >> /var/www/html/wp-config.php"
```

### Cache problemi

```bash
# Forza pulizia cache
docker exec wordpress-prod rm -rf /var/www/html/wp-content/cache/*
```

---

## Comandi Diagnostici Utili

```bash
# Stato generale Docker
docker system info
docker system df

# Stato container
docker-compose ps
docker stats

# Log in tempo reale (tutti i container)
docker-compose logs -f

# Ispeziona container
docker inspect wordpress-dev

# Shell interattiva nel container
docker exec -it wordpress-dev bash
docker exec -it mysql-dev bash

# Verifica rete Docker
docker network ls
docker network inspect frost-dev_frontend

# Pulizia Docker (ATTENZIONE!)
docker system prune        # Rimuove container/immagini fermi
docker system prune -a     # Rimuove TUTTO quello inutilizzato
docker volume prune        # Rimuove volumi orfani
```

---

## Contatti e Supporto

Se il problema persiste:

1. Controlla i log: `docker-compose logs > debug.log`
2. Verifica la configurazione: `.env` e `docker-compose.yml`
3. Cerca l'errore su Google con "Docker WordPress [errore]"
4. Consulta la documentazione Docker: https://docs.docker.com/
