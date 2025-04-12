# SABnzbd Setup Guide for Docker Media Server

Diese Anleitung führt dich durch die Einrichtung von SABnzbd mit Sonarr, Radarr und anderen Medienservices in einer Docker-Umgebung.

## Inhaltsverzeichnis
1. [Voraussetzungen](#voraussetzungen)
2. [Einrichtung von SABnzbd](#einrichtung-von-sabnzbd)
3. [Konfiguration der Verzeichnisstruktur](#konfiguration-der-verzeichnisstruktur)
4. [Konfiguration von SABnzbd](#konfiguration-von-sabnzbd)
5. [Verbindung mit Radarr und Sonarr](#verbindung-mit-radarr-und-sonarr)
6. [Einrichtung von Usenet-Providern](#einrichtung-von-usenet-providern)
7. [Einrichtung von Indexern](#einrichtung-von-indexern)
8. [Fehlerbehebung](#fehlerbehebung)
9. [Erweiterte Konfiguration](#erweiterte-konfiguration)
10. [Vergleich: SABnzbd vs. NZBGet](#vergleich-sabnzbd-vs-nzbget)

## Voraussetzungen

Bevor du mit dieser Anleitung beginnst, stelle sicher, dass du Folgendes hast:

- Docker und Docker Compose installiert
- Eine funktionierende Medienserver-Einrichtung mit Radarr, Sonarr, etc.
- Ein Usenet-Provider-Abonnement (kostenpflichtiger Dienst)
- Zugang zu mindestens einem Usenet-Indexer

## Einrichtung von SABnzbd

### 1. SABnzbd zu docker-compose.yml hinzufügen

Füge die folgende Konfiguration zu deiner bestehenden `docker-compose.yml` hinzu:

```yaml
sabnzbd:
  image: lscr.io/linuxserver/sabnzbd:latest
  container_name: sabnzbd
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=Etc/UTC
  volumes:
    - ./config/sabnzbd:/config
    - /mnt/synology/pascal:/downloads
    - /mnt/synology/pascal/incomplete-downloads:/incomplete-downloads #optional
  ports:
    - 8080:8080
  restart: unless-stopped
  networks:
    - media-net
  hostname: sabnzbd
```

### 2. Konfigurationsverzeichnis erstellen

```bash
mkdir -p ./config/sabnzbd
mkdir -p /mnt/synology/pascal/incomplete-downloads
```

### 3. SABnzbd starten

```bash
docker-compose up -d sabnzbd
```

### 4. Auf die Weboberfläche zugreifen

Navigiere zu `http://deine-server-ip:8080` in deinem Browser.
Du wirst durch den ersten Einrichtungsassistenten geführt.

## Konfiguration der Verzeichnisstruktur

Für eine ordnungsgemäße Integration mit Radarr und Sonarr musst du bestimmte Verzeichnisse erstellen:

```bash
# Benötigte Verzeichnisse erstellen
mkdir -p /mnt/synology/pascal/completed/Movies
mkdir -p /mnt/synology/pascal/completed/tv-shows
mkdir -p /mnt/synology/pascal/incomplete-downloads

# Berechtigungen richtig setzen
chown -R 1000:1000 /mnt/synology/pascal/completed
chmod -R 755 /mnt/synology/pascal/completed
chown -R 1000:1000 /mnt/synology/pascal/incomplete-downloads
chmod -R 755 /mnt/synology/pascal/incomplete-downloads
```

## Konfiguration von SABnzbd

In der SABnzbd-Weboberfläche:

### 1. Verzeichnisse konfigurieren

Navigiere zu `Config` → `Folders`:

- **Temporary Download Folder**: `/incomplete-downloads`
- **Completed Download Folder**: `/downloads/completed`
- **Create category folders**: Aktivieren
- **Scripts Folder**: `/config/scripts`

### 2. Kategorien konfigurieren

Navigiere zu `Config` → `Categories`:

#### Für Filme
- Name: `movies`
- Processing:
  - Folder/Path: `/downloads/completed/Movies`

#### Für TV-Shows
- Name: `tv`
- Processing:
  - Folder/Path: `/downloads/completed/tv-shows`

### 3. Konfiguration speichern

Klicke auf `Save Changes` und dann auf `Restart` wenn du dazu aufgefordert wirst.

## Verbindung mit Radarr und Sonarr

### Radarr-Konfiguration

1. Gehe in Radarr zu `Settings` → `Download Clients`
2. Klicke auf den "+"-Button, um einen neuen Download-Client hinzuzufügen
3. Wähle "SABnzbd" aus dem Dropdown-Menü
4. Konfiguriere wie folgt:
   - Name: SABnzbd
   - Host: sabnzbd
   - Port: 8080
   - API Key: *Dein SABnzbd API-Key* (zu finden unter `Config` → `General` → `Security` in SABnzbd)
   - Category: movies
   - Use SSL: Nein
   - Teste die Verbindung, um sicherzustellen, dass sie funktioniert

### Sonarr-Konfiguration

1. Gehe in Sonarr zu `Settings` → `Download Clients`
2. Klicke auf den "+"-Button, um einen neuen Download-Client hinzuzufügen
3. Wähle "SABnzbd" aus dem Dropdown-Menü
4. Konfiguriere wie folgt:
   - Name: SABnzbd
   - Host: sabnzbd
   - Port: 8080
   - API Key: *Dein SABnzbd API-Key* (zu finden unter `Config` → `General` → `Security` in SABnzbd)
   - Category: tv
   - Use SSL: Nein
   - Teste die Verbindung, um sicherzustellen, dass sie funktioniert

## Einrichtung von Usenet-Providern

Du benötigst mindestens einen Usenet-Provider, um Inhalte herunterzuladen.

1. Gehe in SABnzbd zu `Config` → `Servers`
2. Klicke auf `Add Server` (oder `New`), um einen neuen Server hinzuzufügen
3. Konfiguriere den Server mit den Details deines Usenet-Providers:
   - Name: Ein beschreibender Name für deinen Provider
   - Host: Die Serveradresse, die von deinem Usenet-Provider bereitgestellt wird
   - Port: Typischerweise 119 (unverschlüsselt) oder 563 (SSL, empfohlen)
   - Username: Dein Provider-Benutzername
   - Password: Dein Provider-Passwort
   - Connections: Anzahl der von deinem Provider erlaubten Verbindungen
   - SSL: Aktivieren für SSL-Verbindungen (empfohlen)
   - Enable: Aktiviert lassen

### Beliebte Usenet-Provider

Einige beliebte Usenet-Provider sind:
- Newshosting
- Eweka
- Newsgroup Ninja
- UsenetServer
- Newsdemon

Die meisten Provider bieten Testphasen oder vergünstigte Abonnements für den ersten Monat an.

## Einrichtung von Indexern

Indexer sind Dienste, die dir helfen, Inhalte im Usenet zu finden. Du kannst sie direkt in Prowlarr oder in Radarr und Sonarr einrichten.

### Verwendung von Prowlarr (Empfohlen)

1. Gehe zur Prowlarr-Weboberfläche (`http://deine-server-ip:9696`)
2. Gehe zu `Settings` → `Apps` und füge sowohl Radarr als auch Sonarr hinzu
3. Gehe zu `Indexers` und füge deine Usenet-Indexer hinzu
4. Prowlarr synchronisiert diese Indexer automatisch mit Radarr und Sonarr

### Beliebte Usenet-Indexer

Einige beliebte Indexer sind:
- NZBGeek
- DrunkenSlug
- NZBPlanet
- NZBFinder
- DOGnzb

Die meisten Indexer erfordern eine Registrierung und können eine kleine Gebühr haben.

## Fehlerbehebung

### Häufige Probleme und Lösungen

#### SABnzbd-Verzeichnisprobleme mit Radarr/Sonarr
Wenn du Fehler siehst wie:
> "Download client SABnzbd places downloads in /downloads/completed/Movies but this directory does not appear to exist inside the container"

1. Überprüfe, ob deine Verzeichnisstruktur existiert, wie unter [Konfiguration der Verzeichnisstruktur](#konfiguration-der-verzeichnisstruktur) angegeben
2. Überprüfe, ob die SABnzbd-Kategorien korrekt konfiguriert sind
3. Starte sowohl den SABnzbd- als auch den Radarr/Sonarr-Container neu:
   ```bash
   docker-compose restart sabnzbd radarr sonarr
   ```

#### Berechtigungsprobleme
Wenn SABnzbd nicht in Verzeichnisse schreiben kann:

1. Überprüfe die Eigentümerschaft der Verzeichnisse:
   ```bash
   ls -la /mnt/synology/pascal/completed
   ```
2. Behebe die Berechtigungen bei Bedarf:
   ```bash
   chown -R 1000:1000 /mnt/synology/pascal
   chmod -R 755 /mnt/synology/pascal
   ```

#### Verbindungsprobleme zum Usenet-Provider
Wenn SABnzbd keine Verbindung zu deinem Usenet-Provider herstellen kann:

1. Überprüfe deine Internetverbindung
2. Überprüfe, ob deine Usenet-Provider-Zugangsdaten korrekt sind
3. Versuche, die alternative Serveradresse deines Providers zu verwenden
4. Überprüfe, ob dein ISP Usenet-Ports (119 oder 563) blockiert

## Erweiterte Konfiguration

### Leistungsoptimierung

Für bessere Leistung mit SABnzbd:

1. Gehe zu `Config` → `Switches`:
   - Aktiviere `Direct Unpack` für schnellere Extraktion
   - Aktiviere `Quick Check` für schnellere PAR2-Prüfungen bei intakten Downloads

2. Gehe zu `Config` → `General`:
   - Passe `Article Cache Limit` an, wenn du über ausreichend RAM verfügst (z.B. 1024 MB oder höher)

### SSL/TLS-Konfiguration

Für sichere Verbindungen zu deinem Usenet-Provider:

1. Gehe zu `Config` → `Servers`
2. Stelle sicher, dass `SSL` aktiviert ist
3. Verwende Port `563` anstelle von `119`

### Geplante Downloads

Um die Bandbreitennutzung zu verwalten:

1. Gehe zu `Config` → `Scheduling`
2. Füge Zeitfenster mit reduzierter Download-Geschwindigkeit während Spitzennutzungszeiten hinzu

### Backup und Wiederherstellung

Um deine SABnzbd-Konfiguration zu sichern:

1. Gehe zu `Config` → `Backup/Restore`
2. Klicke auf `Create backup`
3. Lade die Sicherungsdatei herunter

Zur Wiederherstellung:
1. Gehe zu `Config` → `Backup/Restore`
2. Klicke auf `Browse...` und wähle deine Sicherungsdatei aus
3. Klicke auf `Restore`

## Vergleich: SABnzbd vs. NZBGet

Beide sind ausgezeichnete Usenet-Downloader, aber sie haben unterschiedliche Stärken:

### SABnzbd
- **Vorteile**:
  - Benutzerfreundlichere Oberfläche
  - Mehr integrierte Funktionen
  - Robustere Reparatur- und Extraktionsfunktionen
  - Häufigere Updates
  - Bessere Fortschrittsberichterstattung

- **Nachteile**:
  - Etwas höherer Ressourcenbedarf
  - Kann bei sehr hohen Geschwindigkeiten und vielen Verbindungen langsamer sein

### NZBGet
- **Vorteile**:
  - Leichtgewichtiger, geringerer Ressourcenverbrauch
  - Bessere Leistung auf ressourcenbeschränkten Systemen (wie NAS-Geräten)
  - Effizientere CPU-Nutzung
  - Bessere Leistung bei sehr hohen Bandbreiten

- **Nachteile**:
  - Weniger intuitive Benutzeroberfläche
  - Weniger integrierte Funktionen

**Empfehlung**: SABnzbd ist für die meisten Benutzer die einsteigerfreundlichere Option. Wenn du jedoch ein System mit begrenzten Ressourcen oder eine extrem schnelle Internetverbindung hast, könnte NZBGet die bessere Wahl sein.

---

Mit dieser Anleitung solltest du eine voll funktionsfähige SABnzbd-Einrichtung haben, die in deinen Docker-basierten Medienserver integriert ist. Denke daran, deine Container regelmäßig zu aktualisieren, um neue Funktionen und Sicherheitsupdates zu erhalten:

```bash
docker-compose pull
docker-compose up -d
```

Viel Spaß beim Downloaden!
