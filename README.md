# Frost Theme + Custom Plugin Boilerplate

> **WordPress agency starter kit** basato su Frost theme + FSE (Full Site Editing) + Custom Gutenberg Blocks Plugin

## 🎯 Obiettivo

Questo repository è il **boilerplate definitivo** per progetti WordPress agency/freelancer che richiedono:

- ✅ Design premium e performante
- ✅ Full Site Editing nativo (no page builders esterni)
- ✅ Blocchi Gutenberg custom riutilizzabili
- ✅ Scalabilità tra progetti diversi
- ✅ Manutenibilità e standard WordPress
- ✅ Zero costi di licenza ricorrenti

## 📁 Struttura del progetto
```
frost-theme-custom-plugin/
├── themes/
│   └── frost-child/              # Child theme personalizzato
│       ├── theme.json            # Design system (colori, font, spacing)
│       ├── style.css             # Stili child theme
│       ├── functions.php         # Enqueue e customizzazioni
│       ├── patterns/             # Pattern Gutenberg riutilizzabili
│       │   ├── hero-dark.php
│       │   ├── cta-gold-accent.php
│       │   ├── testimonial-section.php
│       │   └── footer-editorial.php
│       └── templates/
│           ├── page-bio-link.php # Template bio link → Amazon
│           └── single-book.php   # Template libri (se custom post type)
│
├── plugins/
│   └── agency-custom-blocks/     # Plugin blocchi custom
│       ├── agency-custom-blocks.php  # Main plugin file
│       ├── blocks/
│       │   ├── book-card/        # Card libro per cataloghi editoriali
│       │   │   ├── block.json
│       │   │   ├── render.php
│       │   │   └── style.css
│       │   ├── testimonial/      # Blocco testimonianza
│       │   │   ├── block.json
│       │   │   ├── render.php
│       │   │   └── style.css
│       │   ├── cta-section/      # Call-to-action premium
│       │   │   ├── block.json
│       │   │   ├── render.php
│       │   │   └── style.css
│       │   └── amazon-affiliate/  # Link affiliazione Amazon
│       │       ├── block.json
│       │       ├── render.php
│       │       └── style.css
│       └── inc/
│           ├── register-blocks.php
│           └── helpers.php
│
├── docker-compose.yml            # Development environment
├── .env.example                  # Environment variables template
├── .gitignore
└── README.md                     # Questo file
```

## 🚀 Quick Start

### Prerequisiti

- Docker + Docker Compose
- WordPress 6.4+ (con FSE support)
- Frost theme installato (parent theme)

### Setup Development

1. **Clone del repository**
```bash
   git clone https://github.com/tuo-username/frost-theme-custom-plugin.git
   cd frost-theme-custom-plugin
```

2. **Setup Docker environment**
```bash
   cp .env.example .env
   docker-compose up -d
```

3. **Accedi a WordPress**
   - URL: `http://localhost:8080`
   - Admin: `http://localhost:8080/wp-admin`
   - User: `admin` / Pass: `password` (modifica in `.env`)

4. **Installa Frost parent theme**
```bash
   # Da wp-admin → Appearance → Themes → Add New → Search "Frost"
   # Oppure via WP-CLI:
   docker exec -it wp-container wp theme install frost --activate
```

5. **Attiva child theme e plugin**
```bash
   # Copia file nel container (se non usi bind mounts)
   # Oppure attiva da wp-admin:
   # - Themes → Frost Child → Activate
   # - Plugins → Agency Custom Blocks → Activate
```

## 🎨 Design System (theme.json)

Il child theme include un design system pre-configurato con:

- **Colori:** Dark editorial palette + gold accents
- **Typography:** System moderne con fallback eleganti
- **Spacing:** Scale 8px-based per coerenza
- **Layout:** Mobile-first responsive breakpoints

### Customizzazione colori

Modifica `themes/frost-child/theme.json`:
```json
{
  "settings": {
    "color": {
      "palette": [
        {
          "slug": "primary-dark",
          "color": "#0a0a0a",
          "name": "Primary Dark"
        },
        {
          "slug": "gold-accent",
          "color": "#d4af37",
          "name": "Gold Accent"
        }
      ]
    }
  }
}
```

## 🧩 Blocchi Custom Disponibili

### 1. Book Card
Blocco per visualizzare libri in cataloghi editoriali

**Attributi:**
- `title` (string): Titolo libro
- `author` (string): Autore
- `coverImage` (string): URL immagine copertina
- `amazonLink` (string): Link affiliazione Amazon
- `excerpt` (string): Descrizione breve

**Utilizzo:**
```html
<!-- wp:agency-blocks/book-card {
  "title": "Il Nome della Rosa",
  "author": "Umberto Eco",
  "coverImage": "https://...",
  "amazonLink": "https://amzn.to/..."
} /-->
```

### 2. Testimonial
Blocco testimonianza con avatar e rating

**Attributi:**
- `authorName` (string)
- `authorRole` (string)
- `testimonialText` (string)
- `rating` (number): 1-5 stelle
- `avatarUrl` (string)

### 3. CTA Section
Call-to-action premium con animazioni

**Attributi:**
- `heading` (string)
- `description` (string)
- `buttonText` (string)
- `buttonUrl` (string)
- `backgroundColor` (string): slug colore da theme.json

### 4. Amazon Affiliate Link
Link ottimizzato per conversioni Amazon

**Attributi:**
- `productName` (string)
- `affiliateUrl` (string)
- `buttonStyle` (string): "primary" | "secondary" | "gold"

## 📦 Deployment

### Setup su VPS (Docker)

1. **Clone sul server**
```bash
   ssh user@your-vps.com
   cd /var/www
   git clone https://github.com/tuo-username/frost-theme-custom-plugin.git
   cd frost-theme-custom-plugin
```

2. **Configura environment**
```bash
   cp .env.example .env
   nano .env  # Modifica WORDPRESS_DB_*, domain, ecc.
```

3. **Deploy con Docker**
```bash
   docker-compose -f docker-compose.prod.yml up -d
```

4. **Setup Caddy reverse proxy** (se applicabile)
```bash
   # Vedi documentazione Caddy per SSL automatico
```

### Deployment su hosting tradizionale

1. **Upload tramite FTP/SFTP**
   - `themes/frost-child/` → `/wp-content/themes/`
   - `plugins/agency-custom-blocks/` → `/wp-content/plugins/`

2. **Attiva da wp-admin**
   - Themes → Frost Child
   - Plugins → Agency Custom Blocks

## 🔧 Development Workflow

### Modificare blocchi esistenti

1. Edita file in `plugins/agency-custom-blocks/blocks/[nome-blocco]/`
2. Modifica `block.json` per attributi
3. Modifica `render.php` per markup
4. Modifica `style.css` per styling
5. Ricarica pagina WordPress (no rebuild necessario!)

### Aggiungere nuovo blocco
```bash
# Crea cartella blocco
mkdir plugins/agency-custom-blocks/blocks/my-new-block

# Crea file necessari
touch plugins/agency-custom-blocks/blocks/my-new-block/block.json
touch plugins/agency-custom-blocks/blocks/my-new-block/render.php
touch plugins/agency-custom-blocks/blocks/my-new-block/style.css

# Registra in inc/register-blocks.php
```

### Hot reload (no reinstallazione plugin)

Con Docker bind mounts attivi, le modifiche ai file PHP sono **immediate**:
- Modifica file `.php` o `.json`
- Ricarica pagina (Ctrl+R)
- Nessuna reinstallazione necessaria ✅

## 🎯 Use Cases

### Caso 1: Sito catalogo libri (Edizioni Rosi)
- Child theme: Design dark editorial
- Blocchi: Book Card + Amazon Affiliate
- Custom Post Type: `books` (tramite plugin o codice)
- Template: `single-book.php` per dettaglio libro

### Caso 2: Bio link page autore → Amazon
- Template: `page-bio-link.php`
- Blocchi: CTA Section + Amazon Affiliate
- Analytics: GA4 event tracking per click Amazon

### Caso 3: Landing page servizi
- Pattern: Hero Dark + Testimonial Section + CTA
- Blocchi riutilizzabili da library
- Mobile-first responsive

## 🛠 Troubleshooting

### Blocchi non visibili in editor
```bash
# Flush rewrite rules
docker exec -it wp-container wp rewrite flush

# Verifica registrazione blocchi
docker exec -it wp-container wp plugin list
```

### Child theme non carica stili

Verifica in `functions.php`:
```php
wp_enqueue_style('frost-child-style', ...);
```

### Modifiche non si vedono

1. Svuota cache browser (Ctrl+Shift+R)
2. Disabilita plugin cache (WP Super Cache, etc.)
3. Verifica bind mounts in `docker-compose.yml`

## 📚 Risorse

- [Frost Theme Docs](https://frostwp.com/)
- [Block Editor Handbook](https://developer.wordpress.org/block-editor/)
- [theme.json Reference](https://developer.wordpress.org/block-editor/reference-guides/theme-json-reference/)
- [Server-side Blocks Guide](https://developer.wordpress.org/block-editor/how-to-guides/block-tutorial/creating-dynamic-blocks/)

## 🤝 Contributing

Questo è un boilerplate personale per uso agency. Fork liberamente per i tuoi progetti!

## 📄 License

GPL v2 or later (compatibile con WordPress)

---

**Made with ❤️ for modern WordPress development**
```

---

# 🚀 PROMPT PER CLAUDE CODE

Copia e incolla questo prompt quando apri Claude Code sul repository:
```
Ciao! Devi creare un boilerplate completo per WordPress basato su Frost theme + Custom Blocks Plugin.

**Contesto:**
Sono uno sviluppatore WordPress agency/freelancer. Ho bisogno di uno starter kit riutilizzabile per progetti client che richiede:
- Design premium (dark theme, gold accents, animazioni eleganti)
- Performance eccellenti
- Full Site Editing (FSE) con Gutenberg
- Blocchi custom server-rendered (no JavaScript build)
- Clienti principalmente settore editoria/publishing

**Hai già il README nel repo.** Usalo come riferimento per capire la struttura.

**Cosa devi creare:**

1. **Child theme Frost (`themes/frost-child/`)**
   - `theme.json` con design system premium:
     * Palette dark editorial: primary-dark (#0a0a0a), secondary-dark (#1a1a1a), gold-accent (#d4af37), off-white (#f5f5f5)
     * Typography: system fonts moderne con fallback eleganti
     * Spacing scale: 8px-based (xs: 8px, sm: 16px, md: 24px, lg: 48px, xl: 64px)
     * Layout: container max-width 1200px, wide 1400px
   - `style.css` con header info child theme
   - `functions.php` per enqueue parent + child styles
   - Pattern file in `patterns/`:
     * `hero-dark.php`: Hero section dark con gold accent CTA
     * `cta-gold-accent.php`: Call-to-action premium
     * `testimonial-section.php`: Sezione testimonianze
     * `footer-editorial.php`: Footer elegante per siti editoriali
   - Template file in `templates/`:
     * `page-bio-link.php`: Template per bio link page → Amazon

2. **Plugin blocchi custom (`plugins/agency-custom-blocks/`)**
   - File principale `agency-custom-blocks.php` con header plugin
   - `inc/register-blocks.php`: logica registrazione blocchi
   - Blocchi in `blocks/` (tutti server-rendered con PHP callback):
     
     **a) `book-card/`** (card libro per cataloghi)
     - `block.json` con attributi: title, author, coverImage, amazonLink, excerpt, price
     - `render.php`: markup card elegante con hover effects
     - `style.css`: styling premium responsive
     
     **b) `testimonial/`** (blocco testimonianza)
     - `block.json` con attributi: authorName, authorRole, testimonialText, rating, avatarUrl
     - `render.php`: layout testimonianza con avatar e stelle rating
     - `style.css`: styling elegante
     
     **c) `cta-section/`** (call-to-action premium)
     - `block.json` con attributi: heading, description, buttonText, buttonUrl, backgroundColor
     - `render.php`: CTA con animazioni subtle al hover
     - `style.css`: gold accents, dark background options
     
     **d) `amazon-affiliate/`** (link Amazon ottimizzato)
     - `block.json` con attributi: productName, affiliateUrl, buttonStyle (primary/secondary/gold)
     - `render.php`: button Amazon con tracking-ready attributes
     - `style.css`: stili button premium

3. **Docker setup (`docker-compose.yml`)**
   - WordPress latest + MySQL 8
   - Bind mounts per hot reload (no named volumes)
   - Porte: WordPress 8080, MySQL 3306
   - phpMyAdmin opzionale su porta 8081
   - Network custom per isolamento

4. **Environment template (`.env.example`)**
   - Variabili: WORDPRESS_DB_NAME, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD, WORDPRESS_TABLE_PREFIX, WORDPRESS_DEBUG

5. **`.gitignore`**
   - Ignora: `.env`, `node_modules/`, `vendor/`, `*.log`, `.DS_Store`, `wp-content/uploads/`

**Requisiti tecnici:**
- Tutti i blocchi devono usare `render_callback` (server-side rendering)
- Zero JavaScript build process
- Mobile-first responsive design
- Accessibility: semantic HTML, ARIA labels dove necessario
- Performance: lazy loading immagini, CSS minimo necessario
- Commenti inline dettagliati in italiano nei file chiave

**Design guidelines:**
- Palette dark premium (evita bianco puro, usa off-white #f5f5f5)
- Gold accent (#d4af37) solo per CTA primarie e dettagli premium
- Animazioni: transitions veloci (200-300ms), no animazioni pesanti
- Typography: line-height generoso (1.6-1.8 per body text)
- Spacing: usa la scale 8px per consistenza verticale

**Priorità:**
1. Funzionalità prima di estetica (ma mantieni standard premium)
2. Codice pulito e commentato (deve essere riusabile!)
3. Segui WordPress Coding Standards
4. Tutti i file devono avere header DocBlock con descrizione

**Inizia creando la struttura cartelle completa, poi genera file uno per uno.**

Fammi sapere quando hai finito e dammi un riepilogo di cosa hai creato! 🚀