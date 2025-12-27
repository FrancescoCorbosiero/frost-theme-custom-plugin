# Caddy Docker Proxy Setup

Guida completa per configurare **Caddy Docker Proxy** sul tuo VPS.
Questa configurazione è **one-time** e servirà tutti i tuoi progetti WordPress.

## Indice

1. [Cos'è Caddy Docker Proxy](#cosè-caddy-docker-proxy)
2. [Vantaggi del setup multi-sito](#vantaggi-del-setup-multi-sito)
3. [Prerequisiti VPS](#prerequisiti-vps)
4. [Installazione](#installazione)
5. [Configurazione DNS](#configurazione-dns)
6. [Test SSL](#test-ssl)
7. [Multi-sito esempi](#multi-sito-esempi)
8. [Troubleshooting](#troubleshooting)

---

## Cos'è Caddy Docker Proxy

**Caddy Docker Proxy** è un reverse proxy automatico che:

- Genera certificati SSL Let's Encrypt automaticamente
- Configura il routing tramite Docker labels (zero config files)
- Gestisce il rinnovo certificati in background
- Supporta HTTP/2 e HTTP/3 (QUIC)

### Come funziona

```
Internet
    ↓
┌───────────────────────────────────────────┐
│  Caddy Docker Proxy (:80, :443)           │
│  - SSL automatico per ogni dominio        │
│  - Legge labels dai container Docker      │
│  - Routing automatico                     │
└───────────────────────────────────────────┘
    ↓                    ↓                    ↓
[site1.com]        [site2.com]        [staging.site1.com]
WordPress A        WordPress B        WordPress C
```

Ogni container WordPress ha labels come:
```yaml
labels:
  caddy: example.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

Caddy Docker Proxy legge queste labels e configura automaticamente:
- Reverse proxy verso il container
- Certificato SSL per il dominio
- Security headers

---

## Vantaggi del setup multi-sito

| Aspetto | Caddy per progetto | Caddy Docker Proxy |
|---------|-------------------|-------------------|
| Container Caddy | N (uno per sito) | 1 (condiviso) |
| Porte usate | N × (80, 443) | 1 × (80, 443) |
| Certificati SSL | Gestione separata | Centralizzata |
| Configurazione | Caddyfile per sito | Solo Docker labels |
| Risorse RAM | ~50MB × N | ~50MB totale |
| Aggiornamenti | N container | 1 container |

**Risparmio tipico con 5 siti**: ~200MB RAM, zero Caddyfile da mantenere

---

## Prerequisiti VPS

### Sistema operativo
- Ubuntu 22.04+ (consigliato)
- Debian 11+
- Qualsiasi Linux con Docker

### Docker installato

```bash
# Verifica installazione Docker
docker --version
docker compose version

# Se non installato, installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout e login per applicare il gruppo
```

### Porte aperte (firewall UFW)

```bash
# Verifica stato UFW
sudo ufw status

# Apri porte necessarie
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP (redirect a HTTPS)
sudo ufw allow 443/tcp  # HTTPS

# Abilita UFW se non attivo
sudo ufw enable
```

### Verifica porte libere

```bash
# Verifica che le porte 80 e 443 non siano occupate
sudo ss -tlnp | grep -E ':80|:443'

# Se occupate, identifica il processo
sudo lsof -i :80
sudo lsof -i :443
```

---

## Installazione

### 1. Crea la directory per Caddy

```bash
sudo mkdir -p /opt/caddy-proxy
cd /opt/caddy-proxy
```

### 2. Crea il network Docker condiviso

```bash
docker network create caddy
```

Questo network sarà condiviso da tutti i tuoi progetti WordPress.

### 3. Crea il file docker-compose.yml

```bash
sudo nano docker-compose.yml
```

Contenuto:

```yaml
# ============================================
# CADDY DOCKER PROXY
# ============================================
# Reverse proxy centralizzato per tutti i siti
# SSL automatico via Let's Encrypt
# Zero-config: legge labels dai container

services:
  caddy:
    image: lucaslorentz/caddy-docker-proxy:ci-alpine
    container_name: caddy-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3 (QUIC)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - caddy
    environment:
      # Email per certificati Let's Encrypt (opzionale ma consigliato)
      CADDY_INGRESS_NETWORKS: caddy
    labels:
      # Abilita Caddy Docker Proxy per se stesso
      caddy: ""

networks:
  caddy:
    external: true

volumes:
  caddy_data:
  caddy_config:
```

### 4. Avvia Caddy Docker Proxy

```bash
docker compose up -d

# Verifica che sia running
docker compose ps
docker logs caddy-proxy
```

### 5. Verifica network

```bash
# Il network caddy deve esistere
docker network ls | grep caddy

# Verifica che Caddy sia connesso
docker network inspect caddy
```

---

## Configurazione DNS

Per ogni dominio che vuoi servire, configura un **A record** presso il tuo registrar DNS.

### Esempio: singolo dominio

```
example.com       A     123.456.789.10    (IP del tuo VPS)
www.example.com   A     123.456.789.10    (opzionale, redirect)
```

### Esempio: staging + produzione

```
example.com           A     123.456.789.10
staging.example.com   A     123.456.789.10
```

### Verifica propagazione DNS

```bash
# Sul tuo computer locale
dig example.com +short
# Deve mostrare l'IP del VPS

# O con nslookup
nslookup example.com
```

**Nota**: La propagazione DNS può richiedere fino a 48 ore, ma spesso è completa in minuti.

---

## Test SSL

Dopo aver deployato un sito con i labels corretti, verifica SSL:

### 1. Test con curl

```bash
curl -I https://example.com
# Deve rispondere con HTTP/2 200
```

### 2. Verifica certificato

```bash
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
# Mostra date validità certificato
```

### 3. Test online

- [SSL Labs](https://www.ssllabs.com/ssltest/) - Test completo
- [SSL Checker](https://www.sslshopper.com/ssl-checker.html) - Verifica veloce

---

## Multi-sito esempi

### Esempio 1: Singolo sito

```yaml
# docker-compose.yml del progetto
services:
  wordpress:
    image: wordpress:6-php8.3-apache
    networks:
      - caddy
    labels:
      caddy: example.com
      caddy.reverse_proxy: "{{upstreams 80}}"

networks:
  caddy:
    external: true
```

### Esempio 2: Stesso sito con www redirect

```yaml
labels:
  caddy: example.com
  caddy.reverse_proxy: "{{upstreams 80}}"
  # Aggiungi anche il www
  caddy_1: www.example.com
  caddy_1.redir: "https://example.com{uri} permanent"
```

### Esempio 3: Multi-sito (progetti separati)

**Progetto A** (`/var/www/site-a/docker/production/docker-compose.yml`):
```yaml
labels:
  caddy: site-a.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

**Progetto B** (`/var/www/site-b/docker/production/docker-compose.yml`):
```yaml
labels:
  caddy: site-b.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

**Progetto C** (`/var/www/site-c/docker/production/docker-compose.yml`):
```yaml
labels:
  caddy: site-c.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

Tutti e tre usano lo stesso Caddy Docker Proxy e network `caddy`.

### Esempio 4: Staging + Produzione stesso progetto

```yaml
# Produzione: docker/production/docker-compose.yml
labels:
  caddy: example.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

```yaml
# Staging: docker/staging/docker-compose.yml
labels:
  caddy: staging.example.com
  caddy.reverse_proxy: "{{upstreams 80}}"
```

---

## Troubleshooting

### SSL non si attiva

**Sintomo**: Certificato non valido o errore connessione

**Soluzioni**:

1. **Verifica DNS**
   ```bash
   dig example.com +short
   # Deve mostrare l'IP del VPS
   ```

2. **Verifica porte aperte**
   ```bash
   sudo ufw status
   # Deve mostrare 80 e 443 ALLOW
   ```

3. **Controlla logs Caddy**
   ```bash
   docker logs caddy-proxy -f --tail 100
   # Cerca errori ACME o certificati
   ```

4. **Verifica network**
   ```bash
   docker network inspect caddy
   # Deve contenere sia caddy-proxy che il tuo container wordpress
   ```

### Container non raggiungibile

**Sintomo**: 502 Bad Gateway

**Soluzioni**:

1. **Verifica container running**
   ```bash
   docker compose ps
   # WordPress deve essere Up
   ```

2. **Verifica network condiviso**
   ```bash
   docker network inspect caddy
   # Il container WordPress deve essere nella lista
   ```

3. **Verifica labels**
   ```bash
   docker inspect project-wordpress | grep -A 20 Labels
   # Deve mostrare i labels caddy.*
   ```

### Rate limit Let's Encrypt

**Sintomo**: Troppi tentativi, certificato negato

Let's Encrypt ha limiti:
- 50 certificati/settimana per dominio principale
- 5 errori/ora per dominio

**Soluzioni**:

1. **Usa staging per test**
   ```yaml
   environment:
     CADDY_ACME_CA: https://acme-staging-v02.api.letsencrypt.org/directory
   ```

2. **Aspetta 1 ora** per reset rate limit

3. **Verifica DNS corretto** prima di riprovare

### Firewall blocca il traffico

```bash
# Verifica regole iptables
sudo iptables -L -n

# Reset regole se necessario (attenzione!)
sudo iptables -F

# Riconfigura UFW
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### Caddy non legge i labels

**Sintomo**: Nuovo container non viene rilevato

**Soluzioni**:

1. **Verifica CADDY_INGRESS_NETWORKS**
   ```yaml
   environment:
     CADDY_INGRESS_NETWORKS: caddy
   ```

2. **Riavvia Caddy dopo modifiche**
   ```bash
   docker restart caddy-proxy
   ```

3. **Verifica Docker socket**
   ```bash
   ls -la /var/run/docker.sock
   # Deve essere leggibile dal container
   ```

---

## Manutenzione

### Aggiornare Caddy Docker Proxy

```bash
cd /opt/caddy-proxy
docker compose pull
docker compose up -d
```

### Backup certificati

```bash
# I certificati sono in un Docker volume
docker run --rm -v caddy_data:/data -v $(pwd):/backup \
  alpine tar cvf /backup/caddy-certs-backup.tar /data
```

### Logs rotatati

Caddy gestisce i log internamente. Per visualizzarli:

```bash
# Ultimi 100 log
docker logs caddy-proxy --tail 100

# Follow in real-time
docker logs caddy-proxy -f

# Con timestamp
docker logs caddy-proxy -t --tail 50
```

---

## Risorse

- [Caddy Docker Proxy GitHub](https://github.com/lucaslorentz/caddy-docker-proxy)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
