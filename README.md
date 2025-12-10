# Raspberry Pi Media Server Setup

Personal automated setup script for configuring a Raspberry Pi as a media server with Docker-based services.

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

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/martinshields/pisys.git
   cd pisys
   ```

2. Run the setup script:
   ```bash
   ./runsetup.sh
   ```

3. Follow the prompts to:
   - Select storage drive to mount
   - Configure folder permissions
   - Set up automatic mounting (optional)

4. After completion:
   - Log out and back in for group changes
   - Edit `/opt/media-docker/docker-compose.yaml` with VPN credentials
   - Start services: `cd /opt/media-docker && docker compose up -d`

Full documentation is generated at `setupcomplete.md` after installation.

## Requirements

- Raspberry Pi (tested on RPi 5)
- External storage drive
- Internet connection
- Debian-based OS (Raspberry Pi OS)

## Note

This is my personal Raspberry Pi configuration. Review and modify the scripts to suit your needs before running.

## License

MIT
