# Raspberry Pi Media Server Setup

Fully automated setup for deploying a complete media server stack on Raspberry Pi with VPN-protected torrenting, automated media management, and network-wide ad blocking.

## What It Installs

### System Packages
- **Development**: Neovim 0.11.2+, Git, build tools
- **Shell**: Zsh with Oh-My-Zsh (pmcgee theme)
- **Utilities**: htop, fastfetch, vifm, lazygit, lazydocker, fzf, bat, speedtest-cli
- **Docker**: docker.io, docker-compose

### Docker Services
- **Jellyfin**: Media streaming server
- **Sonarr/Radarr**: Automated TV show and movie management
- **Deluge**: Torrent client with VPN protection (gluetun)
- **Pi-hole**: Network-wide ad blocking
- **Portainer**: Docker container management UI
- **Watchtower**: Automatic container updates

### Configurations
- Custom Neovim configuration from [martinshields/nvimbu](https://github.com/martinshields/nvimbu)
- Zsh aliases and shell customizations
- Automated storage structure setup at `/mnt/storage`
- User group permissions for media and Docker management

## Quick Start

```bash
git clone https://github.com/martinshields/pisys.git
cd pisys
./runsetup.sh
```

**That's it!** The script handles everything. See **[QUICKSTART.md](QUICKSTART.md)** for the complete step-by-step deployment guide.

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Complete deployment guide from start to finish
- **[POSTINSTALL.md](POSTINSTALL.md)** - Detailed service configuration (Deluge, Prowlarr, Sonarr, Radarr, Jellyfin)
- **[CLAUDE.md](CLAUDE.md)** - Architecture overview and technical reference
- **setupcomplete.md** - Generated after installation with your specific IP addresses

## Requirements

- Raspberry Pi (tested on RPi 5)
- External storage drive
- Internet connection
- Debian-based OS (Raspberry Pi OS)
- VPN account (Private Internet Access recommended)

## Features

✅ **Fully Automated** - Single script deployment with interactive prompts
✅ **VPN Protected** - All torrent traffic routed through VPN (gluetun + Deluge)
✅ **Media Automation** - Sonarr/Radarr automatically grab and organize media
✅ **Unified Indexing** - Prowlarr manages all torrent sites in one place
✅ **Beautiful UI** - Jellyfin for streaming, Portainer for Docker management
✅ **Ad Blocking** - Pi-hole for network-wide ad and tracker blocking
✅ **Auto Updates** - Watchtower keeps containers up to date
✅ **Persistent Storage** - Systemd service ensures folder structure on boot
✅ **Developer Friendly** - Custom neovim, zsh, lazygit, lazydocker configs

## Project Structure

```
pisys/
├── runsetup.sh              # Main automated setup script
├── configs/
│   ├── docker-compose.yaml  # Complete Docker stack definition
│   ├── pi-foldersetup.sh    # Storage structure setup
│   └── alias_pi.zsh         # Custom shell aliases
├── QUICKSTART.md            # Step-by-step deployment guide
├── POSTINSTALL.md           # Service configuration guide
├── CLAUDE.md                # Technical reference
└── README.md                # This file
```

## What Gets Deployed

**Location:** `/opt/media-docker/`

**Services:** gluetun → deluge → sonarr → radarr → prowlarr → jellyfin → portainer → watchtower → pihole

**Storage:** `/mnt/storage/` with organized downloads/ and medialibrary/ structure

## Note

This is my personal Raspberry Pi configuration. Review and modify the scripts to suit your needs before running.

## License

MIT
