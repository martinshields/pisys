# Quick Deployment Guide

This guide will help you deploy the entire media server stack on a fresh Raspberry Pi in minutes.

## Prerequisites

- Raspberry Pi (tested on RPi 5) with Raspberry Pi OS installed
- External storage drive (HDD/SSD)
- Internet connection
- SSH access or direct terminal access

## Step 1: Clone the Repository

```bash
git clone https://github.com/martinshields/pisys.git
cd pisys
```

## Step 2: Run the Automated Setup

```bash
./runsetup.sh
```

The script will:
- ✅ Update system packages
- ✅ Install all required tools (htop, lazygit, fastfetch, fzf, neovim, docker, etc.)
- ✅ Configure zsh with Oh-My-Zsh and custom theme
- ✅ Install your custom neovim configuration
- ✅ Set up Docker and add your user to the docker group
- ✅ Install lazydocker for Docker management
- ✅ Create storage directory structure
- ✅ Configure file permissions and groups
- ✅ Copy Docker Compose configuration to `/opt/media-docker/`
- ✅ Set up systemd service for automatic storage structure repair

### During Setup You'll Be Asked:

1. **Which storage drive to mount** - Select from the list of available drives
2. **Add to /etc/fstab?** - Type `y` to auto-mount on boot (recommended)
3. **Choose folder permissions** - Select option 2 (770) for recommended security

## Step 3: Log Out and Back In

**Important!** You must log out and log back in for group changes to take effect.

```bash
logout
# Or press Ctrl+D
```

Log back in via SSH or direct console.

## Step 4: Configure VPN Credentials

Edit the Docker Compose file with your VPN credentials:

```bash
cd /opt/media-docker
nano docker-compose.yaml
```

Update these lines:
```yaml
- OPENVPN_USER=REPLACE_ME      # ← Your PIA username
- OPENVPN_PASSWORD=REPLACE_ME  # ← Your PIA password
```

**Optional:** Change the Pi-hole web password:
```yaml
WEBPASSWORD: ""  # ← Set a password here
```

Save and exit (Ctrl+X, then Y, then Enter).

## Step 5: Start All Services

```bash
docker compose up -d
```

This will download and start all containers:
- gluetun (VPN)
- deluge (Torrent client)
- jellyfin (Media server)
- sonarr (TV shows)
- radarr (Movies)
- prowlarr (Indexer manager)
- portainer (Docker UI)
- watchtower (Auto-updater)
- pihole (Ad-blocker)

## Step 6: Verify Services Are Running

```bash
docker ps
```

You should see all containers running. Check health status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## Step 7: Access Web Interfaces

Get your Raspberry Pi's IP address:
```bash
hostname -I | awk '{print $1}'
```

Then access the services:

| Service   | URL                              |
|-----------|----------------------------------|
| Jellyfin  | http://YOUR_IP:8096              |
| Sonarr    | http://YOUR_IP:8989              |
| Radarr    | http://YOUR_IP:7878              |
| Prowlarr  | http://YOUR_IP:9696              |
| Portainer | http://YOUR_IP:9000              |
| Pi-hole   | http://YOUR_IP/admin             |
| Deluge    | http://YOUR_IP:8112              |

Replace `YOUR_IP` with your Raspberry Pi's IP address.

## Step 8: Complete Service Configuration

Follow the detailed setup instructions in **[POSTINSTALL.md](POSTINSTALL.md)** to:

1. Configure Deluge (change default password)
2. Set up Prowlarr with indexers
3. Connect Prowlarr to Sonarr and Radarr
4. Configure download clients in Sonarr/Radarr
5. Add media libraries to Jellyfin
6. Test your first download

## Quick Commands Reference

### Docker Management
```bash
# View logs (realtime)
docker logs -f <container_name>

# Restart a service
docker compose restart <service_name>

# Stop all services
docker compose down

# Update all services
docker compose pull && docker compose up -d

# Interactive Docker UI
lazydocker
```

### System Management
```bash
# System monitor
htop

# System info
fastfetch

# File manager
vifm

# Speed test
speedtest-cli

# Check public IP (verify VPN)
curl ifconfig.me

# Check VPN IP (should be different from above)
docker exec gluetun wget -qO- https://ipinfo.io
```

### Useful Aliases (auto-loaded in zsh)
```bash
up          # Update system packages
dc          # cd to /opt/media-docker/
checkvpn    # Verify VPN connection
myip        # Show your public IP
ports       # Show listening ports
```

## Troubleshooting

### Services won't start
```bash
# Check Docker daemon is running
sudo systemctl status docker

# Check specific container logs
docker logs <container_name>

# Check VPN connection
docker logs gluetun
```

### Permission issues
```bash
# Verify you're in the correct groups
groups

# Should show: docker media downloaders

# If not, re-run:
sudo usermod -aG docker,media,downloaders $USER
# Then log out and back in
```

### Storage not mounted
```bash
# Check if mounted
mountpoint /mnt/storage

# If not, mount manually
udisksctl mount -b /dev/sdb1

# Repair storage structure
sudo /usr/local/bin/repair_storage_structure.sh
```

### VPN not working (Deluge can't download)
```bash
# Check gluetun status
docker logs gluetun | tail -20

# Verify VPN IP is different from your real IP
docker exec gluetun wget -qO- https://ipinfo.io
curl ifconfig.me
# These should show different IPs
```

## Next Steps

1. Read **[POSTINSTALL.md](POSTINSTALL.md)** for detailed service configuration
2. Add your first TV show/movie via Sonarr/Radarr
3. Configure automatic notifications (optional)
4. Set up remote access (optional)

## File Locations

| Component | Location |
|-----------|----------|
| Docker Compose | `/opt/media-docker/docker-compose.yaml` |
| Storage Mount | `/mnt/storage/` |
| Media Library | `/mnt/storage/medialibrary/` |
| Downloads | `/mnt/storage/downloads/` |
| Neovim Config | `~/.config/nvim/` |
| Zsh Config | `~/.zshrc` |
| Custom Aliases | `~/.oh-my-zsh/custom/alias_pi.zsh` |

## Support

- Full documentation: [CLAUDE.md](CLAUDE.md)
- Post-install guide: [POSTINSTALL.md](POSTINSTALL.md)
- Command reference: [command.txt](command.txt)

---

**Total deployment time:** ~15-30 minutes (depending on internet speed for downloads)
