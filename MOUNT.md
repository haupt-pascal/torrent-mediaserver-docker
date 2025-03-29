# Converting GVFS Mounts to Direct CIFS Mounts

This guide explains how to convert your GVFS-mounted Synology shares to direct CIFS mounts for better performance and reliability with your Docker media server.

## Why Convert to Direct CIFS Mounts?

GVFS (GNOME Virtual File System) mounts have some limitations for use with Docker:

1. **Persistence issues**: GVFS mounts may not persist across reboots
2. **User-dependent**: GVFS mounts are tied to your desktop session
3. **Performance**: GVFS may not be as performant as direct mounts for high I/O operations
4. **Docker compatibility**: Docker sometimes has issues accessing GVFS mounts reliably

## Step-by-Step Conversion Process

### 1. Install Required Packages

```bash
sudo apt-get update
sudo apt-get install -y cifs-utils
```

### 2. Create Mount Points

```bash
# Create the main mount point
sudo mkdir -p /mnt/synology/pascal
```

### 3. Create Credentials File

Store your Synology credentials securely:

```bash
sudo nano /root/.smbcredentials
```

Add your Synology login information:

```
username=YOUR_SYNOLOGY_USERNAME
password=YOUR_SYNOLOGY_PASSWORD
```

Secure the file:

```bash
sudo chmod 600 /root/.smbcredentials
```

### 4. Set Up Automatic Mounting

Edit the fstab file:

```bash
sudo nano /etc/fstab
```

Add the following line:

```
//synology.local/torrent-sync /mnt/synology cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,_netdev 0 0
```

> **Note**: Replace `uid=1000,gid=1000` with your actual user and group IDs. You can find these by running `id pascal`.

### 5. Mount the Share

```bash
sudo mount -a
```

### 6. Verify the Mount

```bash
ls -la /mnt/synology/pascal
```

You should see your media folders (movies, music, tv-shows).

### 7. Update docker-compose.yml

Update your docker-compose.yml file to use the direct mounts:

```yaml
volumes:
  - ./config/sonarr:/config
  - /mnt/synology/pascal/tv-shows:/tv
  - /mnt/synology/pascal:/downloads
```

Do this for all services that access Synology shares.

### 8. Restart Docker Services

```bash
cd ~/mediaserver/docker
docker-compose down
docker-compose up -d
```

## Troubleshooting Direct Mounts

### Mount Errors

If you encounter mount errors:

```bash
# Check mount error messages
dmesg | grep -i cifs

# Try mounting with verbose output
sudo mount -t cifs //synology.local/torrent-sync /mnt/synology -o credentials=/root/.smbcredentials,uid=1000,gid=1000 -v
```

### Permission Issues

If container processes can't access the mounted directories:

1. Verify mount permissions:

   ```bash
   ls -la /mnt/synology/pascal
   ```

2. Check if the UID/GID in docker-compose.yml matches your system's user:

   ```bash
   id pascal
   ```

3. Try adding file/directory mode options to the mount:
   ```
   //synology.local/torrent-sync /mnt/synology cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,file_mode=0644,dir_mode=0755 0 0
   ```

### Performance Tuning

For better performance with large media files:

```
//synology.local/torrent-sync /mnt/synology cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,noatime,nodiratime,rsize=131072,wsize=131072 0 0
```

## Reverting to GVFS (If Needed)

If you need to revert to GVFS mounts:

1. Remove the entries from /etc/fstab
2. Unmount the CIFS shares:
   ```bash
   sudo umount /mnt/synology
   ```
3. Update docker-compose.yml to use the original GVFS paths
4. Restart the Docker containers
