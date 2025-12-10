# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Raspberry Pi media server setup featuring a Docker Compose stack for automated media management with VPN protection. The stack includes torrent downloading (Deluge), media streaming (Jellyfin), automated TV/movie management (Sonarr/Radarr), network-wide ad blocking (Pi-hole), and container management (Portainer).

## Architecture

### Service Dependencies
- **gluetun**: VPN container providing network isolation for Deluge
- **deluge**: Torrent client running through gluetun's network stack (network_mode: "service:gluetun")
- **jellyfin**: Media server exposed on port 8096
- **sonarr/radarr**: Automation services for TV shows (8989) and movies (7878)
- **pihole**: DNS/ad-blocker using host network mode
- **portainer**: Web UI for Docker management (port 9000)
- **watchtower**: Automatic container updates (daily checks)

### Volume Structure
The setup expects a mounted storage drive at `/mnt/storage` with this hierarchy:
```
/mnt/storage/
├── downloads/
│   ├── torrents/{movies,tv,music,books}
│   └── usenet/{movies,tv,music,books}
└── medialibrary/{movies,tv,music,books}
```

Local configuration directories are stored alongside docker-compose.yaml:
- `./deluge-config`, `./jellyfin-config`, `./sonarr-config`, `./radarr-config`
- `./pihole/etc-pihole`, `./pihole/etc-dnsmasq.d`
- `./portainer-data`, `./gluetun`

### Network Configuration
- Deluge shares gluetun's network namespace for VPN protection
- Deluge web UI is accessible through gluetun's network on port 8112
- Pi-hole uses host networking to provide DNS services system-wide
- All other services have dedicated port mappings

## Common Commands

### Docker Operations
```bash
# Start all services
docker compose up -d

# View logs (realtime)
docker logs -f <container_name>

# View last 50 lines of logs
docker logs --tail 50 <container_name>

# Restart specific service
docker compose restart <service_name>

# Stop all services
docker compose down

# Update containers
docker compose pull && docker compose up -d
```

### Storage Management
```bash
# Mount external drive (update device path as needed)
udisksctl mount -b /dev/sdb1

# Run initial folder setup (creates directory structure, sets permissions)
./scripts/pi-foldersetup.sh

# Manually repair folder structure
sudo /usr/local/bin/repair_storage_structure.sh
```

### Health Checks
All services include health checks. View status with:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## Initial Setup

### Automated Setup (Recommended)
Run the automated setup script for a fresh Raspberry Pi:
```bash
./runsetup.sh
```

This script will:
1. Install all required packages (htop, lazygit, fastfetch, fzf, 7zip, wget, curl, speedtest-cli, neovim, bat, vifm, zsh, git, docker, docker-compose)
2. Install and configure Oh-My-Zsh with pygmalion theme and plugins (git, sudo, common-aliases, z)
3. Set zsh as the default shell
4. Clone and install custom nvim config from https://github.com/martinshields/nvimbu
5. Copy alias_pi.zsh to ~/.oh-my-zsh/custom/
6. Copy docker-compose.yaml to /opt/media-docker/
7. Run pi-foldersetup.sh to configure storage structure

After running the script:
- Log out and back in for group changes to take effect
- Update `/opt/media-docker/docker-compose.yaml` with VPN credentials and Pi-hole password
- Start services: `cd /opt/media-docker && docker compose up -d`

### Manual Setup
1. Ensure external storage is mounted at `/mnt/storage`
2. Run `./scripts/pi-foldersetup.sh` to create folder structure and set permissions
3. Update `docker-compose.yaml` with VPN credentials (OPENVPN_USER, OPENVPN_PASSWORD)
4. Change Pi-hole web password (WEBPASSWORD)
5. Deploy: `docker compose up -d`

The folder setup script:
- Creates required directory structure
- Sets up `media` and `downloaders` groups
- Applies chosen permissions (default 770)
- Creates systemd service for automatic structure repair on boot

## Configuration Notes

### VPN (Gluetun)
- Provider: Private Internet Access
- Must configure OPENVPN_USER and OPENVPN_PASSWORD
- Health check verifies tun0 interface is up

### Pi-hole
- Uses host network mode to provide system-wide DNS
- Default password in docker-compose.yaml must be changed
- Reverse DNS configured for 10.0.0.1 gateway

### User/Group IDs
All LinuxServer.io containers use PUID=1000 and PGID=1000. Adjust these if your user has different IDs.

### Custom Aliases
The setup includes custom zsh aliases in `alias_pi.zsh`:
- `up`: Update and upgrade system packages
- `vim`, `vi`: Aliased to neovim
- `v`: Open vifm file manager
- `myip`: Display public IP address
- `ports`: Show listening ports
- `speedtest`: Run internet speed test
- Navigation shortcuts: `..`, `...`, `....`

## Service Access

- Jellyfin: http://localhost:8096
- Sonarr: http://localhost:8989
- Radarr: http://localhost:7878
- Portainer: http://localhost:9000
- Pi-hole: http://localhost/admin
- Deluge: Access via gluetun network (port 8112)
