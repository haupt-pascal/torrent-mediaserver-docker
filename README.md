# Media Server Stack - Setup Guide

This guide provides detailed instructions for setting up a complete media server stack using Docker Compose, including Sonarr, Radarr, QBittorrent, Prowlarr, Jellyfin, and Jellyseerr.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Installation Steps](#installation-steps)
  - [1. Prepare the Environment](#1-prepare-the-environment)
  - [2. Set Up Docker and Docker Compose](#2-set-up-docker-and-docker-compose)
  - [3. Create the Docker Compose File](#3-create-the-docker-compose-file)
  - [4. Start the Containers](#4-start-the-containers)
- [Configuration Guide](#configuration-guide)
  - [1. Prowlarr Setup](#1-prowlarr-setup)
  - [2. QBittorrent Setup](#2-qbittorrent-setup)
  - [3. Sonarr Setup](#3-sonarr-setup)
  - [4. Radarr Setup](#4-radarr-setup)
  - [5. Jellyfin Setup](#5-jellyfin-setup)
  - [6. Jellyseerr Setup](#6-jellyseerr-setup)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- A Linux server/NAS/PC with Docker and Docker Compose installed
- Sufficient storage space for media and downloads
- Basic understanding of networking and Docker concepts
- Port forwarding configured on your router (if you want remote access outside your home network)

## Directory Structure

The directory structure is organized as follows:

```
/your_parent_directory/
├── downloads/           <- All downloads shared across services
├── media/               <- All media content
│   ├── tv/              <- TV shows for Sonarr
│   └── movies/          <- Movies for Radarr
│
└── docker/              <- Your docker-compose.yml location
    └── config/          <- All container configurations
        ├── sonarr/
        ├── radarr/
        ├── qbittorrent/
        ├── prowlarr/
        ├── jellyfin/
        └── jellyseerr/
```

## Installation Steps

### 1. Prepare the Environment

First, create the necessary directory structure:

```bash
# Create parent directories
mkdir -p ~/mediaserver
cd ~/mediaserver

# Create the required subdirectories
mkdir -p downloads media/tv media/movies docker/config
cd docker

# Create config subdirectories
mkdir -p config/sonarr config/radarr config/qbittorrent config/prowlarr config/jellyfin config/jellyseerr
```

### 2. Set Up Docker and Docker Compose

If you don't have Docker and Docker Compose installed:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to the docker group (to run docker without sudo)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin
```

Log out and log back in for the group changes to take effect.

### 3. Create the Docker Compose File

Create a `docker-compose.yml` file in the `~/mediaserver/docker` directory with the content provided in the [Docker Compose Configuration](#docker-compose-configuration) section.

### 4. Start the Containers

```bash
# Navigate to your docker directory
cd ~/mediaserver/docker

# Start all containers
docker-compose up -d
```

## Configuration Guide

**IMPORTANT: Follow this exact order of setup to ensure all services work properly together.**

### 1. Prowlarr Setup

Prowlarr provides indexers for your torrent downloads. Set this up first.

1. Access Prowlarr at `http://your-server-ip:9696`
2. Create an admin account and log in
3. Go to "Settings" → "General"
   - Set appropriate configurations for your environment
4. Go to "Indexers" and add the torrent indexers you want to use
   - Add at least 2-3 reliable indexers
5. In "Settings" → "Apps", leave this for now (we'll return after setting up other services)

### 2. QBittorrent Setup

QBittorrent handles download management.

1. **Check the container logs first to get your temporary password:**

   ```bash
   docker logs qbittorrent
   ```

   Look for a line that says: `The WebUI administrator password was not set. A temporary password is provided for this session: XXXXXXXXX`

2. Access QBittorrent WebUI at `http://your-server-ip:8080`
3. Login with:

   - Username: `admin`
   - Password: The temporary password from the logs (example: `D9mvgkKPj`)

4. Change the password immediately after logging in through Settings → WebUI → Authentication
5. Go to "Settings" → "Downloads"
   - Set your download path to `/downloads`
   - Configure your download limits
   - Enable "Start torrent with added torrents paused" if you want manual control
6. Go to "Settings" → "WebUI"
   - Configure authentication settings
   - Enable HTTPS if needed

### 3. Sonarr Setup

Sonarr handles TV shows.

1. Access Sonarr at `http://your-server-ip:8989`
2. Go to "Settings" → "Media Management"
   - Enable "Rename Episodes"
   - Configure "Root Folders" to `/tv`
3. Go to "Settings" → "Download Clients"
   - Add QBittorrent
     - Name: QBittorrent
     - Host: qbittorrent (use the container name)
     - Port: 8080
     - Username: admin
     - Password: (the password you set in QBittorrent)
     - Category: tv-sonarr
4. Return to Prowlarr to configure the connection to Sonarr:
   - In Prowlarr, go to "Settings" → "Apps"
   - Click "+ Add App"
     - Application: Sonarr
     - Sync Level: Full Sync
     - Name: Sonarr
     - Prowlarr Server: http://prowlarr:9696
     - Sonarr Server: http://sonarr:8989
     - API Key: (copy from Sonarr → Settings → General)
     - Click "Test" and then "Save"

### 4. Radarr Setup

Radarr handles movies.

1. Access Radarr at `http://your-server-ip:7878`
2. Go to "Settings" → "Media Management"
   - Enable "Rename Movies"
   - Configure "Root Folders" to `/movies`
3. Go to "Settings" → "Download Clients"
   - Add QBittorrent
     - Name: QBittorrent
     - Host: qbittorrent (use the container name)
     - Port: 8080
     - Username: admin
     - Password: (the password you set in QBittorrent)
     - Category: movies-radarr
4. Return to Prowlarr to configure the connection to Radarr:
   - In Prowlarr, go to "Settings" → "Apps"
   - Click "+ Add App"
     - Application: Radarr
     - Sync Level: Full Sync
     - Name: Radarr
     - Prowlarr Server: http://prowlarr:9696
     - Radarr Server: http://radarr:7878
     - API Key: (copy from Radarr → Settings → General)
     - Click "Test" and then "Save"

### 5. Jellyfin Setup

Jellyfin is your media server.

1. Access Jellyfin at `http://your-server-ip:8096`
2. Follow the initial setup wizard
3. Create an admin user
4. Add media libraries:
   - Add a Movies library:
     - Content Type: Movies
     - Display Name: Movies
     - Folder: `/media/movies`
   - Add a TV Shows library:
     - Content Type: TV Shows
     - Display Name: TV Shows
     - Folder: `/media/tv`
5. Let Jellyfin scan your libraries (this may take time if you already have media)
6. Configure transcoding settings based on your server hardware
7. Set up remote access if needed

### 6. Jellyseerr Setup

Jellyseerr provides a request system for your media server.

1. Access Jellyseerr at `http://your-server-ip:5055`
2. Follow the setup wizard
3. Connect to Jellyfin:
   - Host: http://jellyfin:8096
   - API Key: (generate in Jellyfin → Admin Dashboard → API Keys)
4. Select the Jellyfin libraries to sync
5. Connect to Sonarr:
   - Host: http://sonarr:8989
   - API Key: (from Sonarr → Settings → General)
   - Root Folder: `/tv`
   - Quality Profile: (select appropriate profile)
6. Connect to Radarr:
   - Host: http://radarr:7878
   - API Key: (from Radarr → Settings → General)
   - Root Folder: `/movies`
   - Quality Profile: (select appropriate profile)
7. Configure user permissions and notification settings

## Maintenance

Regular maintenance tasks:

1. **Updating Containers:**

   ```bash
   cd ~/mediaserver/docker
   docker-compose pull
   docker-compose up -d
   ```

2. **Checking Logs:**

   ```bash
   docker-compose logs -f [service_name]
   ```

3. **Cleaning Docker System:**

   ```bash
   docker system prune -a
   ```

4. **Backing Up Configurations:**
   ```bash
   tar -czvf config_backup.tar.gz config/
   ```

## Troubleshooting

Here are some common issues and their solutions:

1. **QBittorrent login issues:**

   - Always check the container logs first to get the temporary password:
     ```bash
     docker logs qbittorrent
     ```
   - Look for: `The WebUI administrator password was not set. A temporary password is provided for this session: XXXXXXXXX`
   - If you still can't log in, you can reset the configuration:
     ```bash
     docker-compose stop qbittorrent
     rm -rf ./config/qbittorrent/*
     docker-compose up -d qbittorrent
     ```
   - Then check the logs again for the new temporary password

2. **Containers not starting:**

   - Check logs: `docker-compose logs -f [service_name]`
   - Verify file permissions: `sudo chown -R 1000:1000 ~/mediaserver`

3. **Apps can't communicate with each other:**

   - Verify network settings
   - Ensure you're using container names for internal communication
   - Check that all services are on the same Docker network

4. **Download problems:**

   - Verify QBittorrent settings
   - Check Prowlarr indexers
   - Ensure file permissions are correct in the download directory

5. **Media not appearing in Jellyfin:**

   - Trigger a manual library scan in Jellyfin
   - Check file permissions
   - Verify the file formats are supported

6. **Path mapping issues:**
   - Ensure consistent paths across all containers
   - Check Docker volume mappings

## Docker Compose Configuration

Here is the complete docker-compose.yml file for reference:

```yaml
version: "3"

services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/sonarr:/config
      - ../media/tv:/tv
      - ../downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped
    networks:
      - media-net
    hostname: sonarr

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/radarr:/config
      - ../media/movies:/movies
      - ../downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped
    networks:
      - media-net
    hostname: radarr

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8080
    volumes:
      - ./config/qbittorrent:/config
      - ../downloads:/downloads
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
    networks:
      - media-net
    hostname: qbittorrent

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/prowlarr:/config
    ports:
      - 9696:9696
    restart: unless-stopped
    networks:
      - media-net
    hostname: prowlarr

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/jellyfin:/config
      - ../media:/media
    ports:
      - 8096:8096
      - 8920:8920 # Optional HTTPS port
      - 7359:7359/udp # Service discovery
      - 1900:1900/udp # DLNA
    restart: unless-stopped
    networks:
      - media-net
    hostname: jellyfin

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/jellyseerr:/app/config
    ports:
      - 5055:5055
    restart: unless-stopped
    networks:
      - media-net
    hostname: jellyseerr
    depends_on:
      - jellyfin
      - radarr
      - sonarr

networks:
  media-net:
    driver: bridge
```

Remember to adjust the `PUID`, `PGID`, and `TZ` environment variables to match your system's user ID, group ID, and timezone.
