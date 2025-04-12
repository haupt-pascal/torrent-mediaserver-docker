# qBittorrent-nox with VueTorrent - Installation and Configuration Guide

This guide will help you set up qBittorrent-nox with the VueTorrent web interface in your Docker environment.

## Overview

- **qBittorrent-nox**: The headless version of qBittorrent that runs without a graphical interface
- **VueTorrent**: A modern, responsive alternative to the standard qBittorrent WebUI
- **Docker setup**: Modular configuration that allows using either the standard qBittorrent or the nox version

## Prerequisites

- Docker and Docker Compose installed
- Basic command line knowledge
- Git (optional)

## Step 1: Download and Set Up Files

1. Save the provided `docker-compose.yml` to your project directory
2. Save the `setup-vuetorrent.sh` script from the artifact to the same directory
3. Make the script executable:

```bash
chmod +x setup-vuetorrent.sh
```

## Step 2: Download and Configure VueTorrent

1. Run the setup script:

```bash
./setup-vuetorrent.sh
```

This script will:
- Download the latest version of VueTorrent
- Create necessary configuration files
- Adjust the Docker Compose file accordingly

## Step 3: Choose Your qBittorrent Version

The docker-compose file includes both qBittorrent versions:
- **qbittorrent**: Standard LinuxServer version with a built-in GUI
- **qbittorrent-nox**: Official headless version, generally more lightweight and faster

To use the standard version, uncomment the `qbittorrent` service and comment out the `qbittorrent-nox` service. For the nox version, do the opposite.

## Step 4: Start Containers

1. Start the containers with:

```bash
docker-compose up -d
```

2. Check that all containers started properly:

```bash
docker-compose ps
```

## Step 5: Access qBittorrent with VueTorrent

1. Open your web browser and navigate to: `http://localhost:8080`
2. Log in with the default credentials:
   - Username: `admin`
   - Password: `adminadmin`
3. Change the password after first login

## Troubleshooting

### If VueTorrent is not displayed:

1. Check the container logs:

```bash
docker-compose logs qbittorrent
# or
docker-compose logs qbittorrent-nox
```

2. Ensure the container is running:

```bash
docker-compose ps
```

3. Run the setup script manually in the container:

```bash
# For standard qBittorrent
docker-compose exec qbittorrent /vuetorrent/setup-qbittorrent-config.sh
docker-compose restart qbittorrent

# For qBittorrent-nox
docker-compose exec qbittorrent-nox /vuetorrent/setup-qbittorrent-config.sh
docker-compose restart qbittorrent-nox
```

### Permission Issues:

If you encounter file permission problems, ensure that the PUID and PGID in your docker-compose.yml match your local user. Check your UID and GID with:

```bash
id
```

## Important Notes

- The default qBittorrent WebUI runs on port 8080. Make sure this port is not used by another application.
- VueTorrent offers additional features and a more modern interface than the standard WebUI.
- All settings and torrents are stored in your configured directory and persist after restarts.

## Performance Comparison

- **qbittorrent-nox**:
  - Pros: Lighter memory footprint, potentially faster
  - Cons: No built-in GUI, relies entirely on WebUI

- **standard qbittorrent**:
  - Pros: More feature-rich by default, familiar interface
  - Cons: Heavier resource usage

## Useful Commands

- Restart container: `docker-compose restart qbittorrent` or `docker-compose restart qbittorrent-nox`
- View logs: `docker-compose logs -f qbittorrent` or `docker-compose logs -f qbittorrent-nox`
- Enter the container: `docker-compose exec qbittorrent /bin/bash` or `docker-compose exec qbittorrent-nox /bin/bash`

## References

- [VueTorrent GitHub Repository](https://github.com/VueTorrent/VueTorrent)
- [qBittorrent Official Documentation](https://github.com/qbittorrent/qBittorrent/wiki)
- [qBittorrent-nox Docker Image](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox)
