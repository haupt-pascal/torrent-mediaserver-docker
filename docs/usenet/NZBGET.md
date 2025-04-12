# NZBGet Setup Guide for Docker Media Server

This guide will walk you through setting up NZBGet with Sonarr, Radarr, and other media services in a Docker environment.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setting Up NZBGet](#setting-up-nzbget)
3. [Configuring Directory Structure](#configuring-directory-structure)
4. [Configuring NZBGet Categories](#configuring-nzbget-categories)
5. [Connecting Radarr and Sonarr](#connecting-radarr-and-sonarr)
6. [Setting Up Usenet Providers](#setting-up-usenet-providers)
7. [Setting Up Indexers](#setting-up-indexers)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Configuration](#advanced-configuration)

## Prerequisites

Before starting this guide, make sure you have:

- Docker and Docker Compose installed
- A working media server setup with Radarr, Sonarr, etc.
- A Usenet provider subscription (paid service)
- Access to at least one Usenet indexer

## Setting Up NZBGet

### 1. Add NZBGet to docker-compose.yml

Add the following configuration to your existing `docker-compose.yml`:

```yaml
nzbget:
  image: lscr.io/linuxserver/nzbget:latest
  container_name: nzbget
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=Etc/UTC
    - NZBGET_USER=nzbget
    - NZBGET_PASS=tegbzn6789
  volumes:
    - ./config/nzbget:/config
    - /mnt/synology/pascal:/downloads
  ports:
    - 6789:6789
  restart: unless-stopped
  networks:
    - media-net
  hostname: nzbget
```

### 2. Create the configuration directory

```bash
mkdir -p ./config/nzbget
```

### 3. Start NZBGet

```bash
docker-compose up -d nzbget
```

### 4. Access the Web Interface

Navigate to `http://your-server-ip:6789` in your browser.
Default login:
- Username: `nzbget`
- Password: `tegbzn6789`

**Important:** Change these default credentials after your first login.

## Configuring Directory Structure

For proper integration with Radarr and Sonarr, you need to create specific directories:

```bash
# Create needed directories
mkdir -p /mnt/synology/pascal/completed/Movies
mkdir -p /mnt/synology/pascal/completed/tv-shows
mkdir -p /mnt/synology/pascal/intermediate
mkdir -p /mnt/synology/pascal/nzb
mkdir -p /mnt/synology/pascal/queue
mkdir -p /mnt/synology/pascal/tmp

# Set proper permissions
chown -R 1000:1000 /mnt/synology/pascal/completed
chmod -R 755 /mnt/synology/pascal/completed
```

## Configuring NZBGet Categories

In the NZBGet web interface:

### 1. Configure Paths

Navigate to `Settings` → `PATHS`:

- MainDir: `/downloads`
- DestDir: `${MainDir}/completed`
- InterDir: `${MainDir}/intermediate`
- NzbDir: `${MainDir}/nzb`
- QueueDir: `${MainDir}/queue`
- TempDir: `${MainDir}/tmp`

### 2. Configure Categories

Navigate to `Settings` → `CATEGORIES`:

#### For Movies
- Name: `Movies`
- DestDir: `${DestDir}/Movies`

#### For TV Shows
- Name: `TV` (or `Series`)
- DestDir: `${DestDir}/tv-shows`

### 3. Save Configuration

Click `Save all changes` at the bottom of the page and then `Reload` when prompted.

## Connecting Radarr and Sonarr

### Radarr Configuration

1. In Radarr, go to `Settings` → `Download Clients`
2. Click the "+" button to add a new download client
3. Select "NZBGet" from the dropdown
4. Configure as follows:
   - Name: NZBGet
   - Host: nzbget
   - Port: 6789
   - Username: nzbget (or your custom username)
   - Password: your-password
   - Category: Movies
   - Use SSL: No
   - Test the connection to ensure it works

### Sonarr Configuration

1. In Sonarr, go to `Settings` → `Download Clients`
2. Click the "+" button to add a new download client
3. Select "NZBGet" from the dropdown
4. Configure as follows:
   - Name: NZBGet
   - Host: nzbget
   - Port: 6789
   - Username: nzbget (or your custom username)
   - Password: your-password
   - Category: TV (or Series, matching what you set in NZBGet)
   - Use SSL: No
   - Test the connection to ensure it works

## Setting Up Usenet Providers

You need at least one Usenet provider to download content.

1. In NZBGet, go to `Settings` → `NEWS-SERVERS`
2. Click `Add` to add a new server
3. Configure the server with details from your Usenet provider:
   - Name: A descriptive name for your provider
   - Host: The server address provided by your Usenet provider
   - Port: Typically 119 (plain) or 563 (SSL, recommended)
   - Username: Your provider username
   - Password: Your provider password
   - Connections: Number of connections allowed by your provider
   - Encryption: `Yes` for SSL connections (recommended)
   - Retention: Leave at default unless your provider specifies a value

### Popular Usenet Providers

Some popular Usenet providers include:
- Newshosting
- Eweka
- Newsgroup Ninja
- UsenetServer
- Newsdemon

Most providers offer trial periods or discounted first-month subscriptions.

## Setting Up Indexers

Indexers are services that help you find content on Usenet. You can set them up directly in Prowlarr, or in Radarr and Sonarr.

### Using Prowlarr (Recommended)

1. Go to Prowlarr web interface (`http://your-server-ip:9696`)
2. Go to `Settings` → `Apps` and add both Radarr and Sonarr
3. Go to `Indexers` and add your Usenet indexers
4. Prowlarr will automatically sync these indexers to both Radarr and Sonarr

### Popular Usenet Indexers

Some popular indexers include:
- NZBGeek
- DrunkenSlug
- NZBPlanet
- NZBFinder
- DOGnzb

Most indexers require registration and may have a small fee.

## Troubleshooting

### Common Issues and Solutions

#### NZBGet directory issues with Radarr/Sonarr
If you see errors like:
> "Download client NZBGet places downloads in /downloads/completed/Movies but this directory does not appear to exist inside the container"

1. Verify your directory structure exists as specified in [Configuring Directory Structure](#configuring-directory-structure)
2. Verify NZBGet categories are correctly configured
3. Restart both the NZBGet and Radarr/Sonarr containers:
   ```bash
   docker-compose restart nzbget radarr sonarr
   ```

#### Permission Issues
If NZBGet cannot write to directories:

1. Verify ownership of directories:
   ```bash
   ls -la /mnt/synology/pascal/completed
   ```
2. Fix permissions if needed:
   ```bash
   chown -R 1000:1000 /mnt/synology/pascal
   chmod -R 755 /mnt/synology/pascal
   ```

#### Connection Issues to Usenet Provider
If NZBGet cannot connect to your Usenet provider:

1. Verify your internet connection
2. Check that your Usenet provider credentials are correct
3. Try using the provider's alternate server address
4. Check if your ISP blocks Usenet ports (119 or 563)

## Advanced Configuration

### Performance Tuning

For better performance with NZBGet:

1. Go to `Settings` → `DOWNLOAD QUEUE`
   - Increase `WriteBuffer` to `1024` for faster disk writes
   - Adjust `ParBuffer` to `800-1000` MB if you have sufficient RAM

2. Go to `Settings` → `PERFORMANCE`
   - Set `ParScan` to `auto` for optimized PAR verification
   - Increase `DirectWrite` to `yes` if your system supports it

### SSL/TLS Configuration

For secure connections to your Usenet provider:

1. Go to `Settings` → `NEWS-SERVERS`
2. Ensure `Encryption` is set to `Yes`
3. Use port `563` instead of `119`

### Scheduled Downloads

To manage bandwidth usage:

1. Go to `Settings` → `SCHEDULER`
2. Add time periods with reduced download speeds during peak usage hours

### Backup and Restore

To backup your NZBGet configuration:

1. Go to `Settings` → `SYSTEM` → `BACKUP`
2. Click `Create Backup`
3. Download the backup file for safekeeping

To restore:
1. Go to `Settings` → `SYSTEM` → `BACKUP`
2. Click `Choose File` and select your backup
3. Click `Restore`

---

With this guide, you should have a fully functional NZBGet setup integrated with your Docker-based media server. Remember to regularly update your containers for new features and security fixes with:

```bash
docker-compose pull
docker-compose up -d
```

Happy downloading!
