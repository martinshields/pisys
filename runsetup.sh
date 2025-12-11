#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Get script directory (must be set early before any cd commands)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root (don't use sudo)"
   exit 1
fi

print_step "Starting Raspberry Pi Setup..."

# =============================================================================
# STEP 1: Install packages
# =============================================================================
print_step "Updating package lists..."
sudo apt update

print_step "Upgrading installed packages..."
sudo apt upgrade -y

print_step "Installing required packages..."
sudo apt install -y \
    htop \
    lazygit \
    fastfetch \
    s-tui \
    stress \
    fzf \
    p7zip-full \
    wget \
    curl \
    speedtest-cli \
    bat \
    vifm \
    zsh \
    git \
    docker.io \
    docker-compose \
    ninja-build \
    gettext \
    cmake \
    unzip \
    build-essential

print_step "Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# =============================================================================
# STEP 2: Install neovim from source
# =============================================================================
print_step "Checking neovim installation..."
REQUIRED_VERSION="0.11.2"
SKIP_INSTALL=false

if command -v nvim &> /dev/null; then
    CURRENT_VERSION=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
    print_step "Found neovim v$CURRENT_VERSION"

    # Compare versions (convert to comparable numbers)
    CURRENT_NUM=$(echo "$CURRENT_VERSION" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    REQUIRED_NUM=$(echo "$REQUIRED_VERSION" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')

    if [ "$CURRENT_NUM" -ge "$REQUIRED_NUM" ]; then
        print_step "Neovim v$CURRENT_VERSION is already installed (>= v$REQUIRED_VERSION), skipping build"
        SKIP_INSTALL=true
    else
        print_warning "Neovim v$CURRENT_VERSION is older than v$REQUIRED_VERSION, will reinstall"
    fi
else
    print_step "Neovim not found, will install v$REQUIRED_VERSION or greater"
fi

if [ "$SKIP_INSTALL" = false ]; then
    cd "$HOME"

    if [ -d "neovim" ]; then
        print_warning "neovim directory already exists, removing..."
        rm -rf neovim
    fi

    print_step "Cloning neovim repository..."
    git clone https://github.com/neovim/neovim.git --branch stable --depth 1
    cd neovim

    print_step "Building neovim (this may take several minutes)..."
    make CMAKE_BUILD_TYPE=Release
    sudo make install

    cd "$HOME"
    rm -rf neovim

    INSTALLED_VERSION=$(nvim --version | head -n1)
    print_step "Neovim installed successfully: $INSTALLED_VERSION"
fi

# =============================================================================
# STEP 3: Install lazydocker from GitHub
# =============================================================================
print_step "Installing lazydocker..."

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        LAZYDOCKER_ARCH="x86_64"
        ;;
    aarch64|arm64)
        LAZYDOCKER_ARCH="arm64"
        ;;
    armv7l)
        LAZYDOCKER_ARCH="armv7"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

print_step "Detected architecture: $ARCH (using $LAZYDOCKER_ARCH binary)"

LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LAZYDOCKER_ARCH}.tar.gz"
tar xf lazydocker.tar.gz lazydocker
sudo install lazydocker /usr/local/bin
rm lazydocker lazydocker.tar.gz
print_step "lazydocker v${LAZYDOCKER_VERSION} installed successfully"

# =============================================================================
# STEP 4: Install Oh-My-Zsh and configure
# =============================================================================
print_step "Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    export RUNZSH=no
    export KEEP_ZSHRC=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    print_warning "Oh-My-Zsh already installed, skipping..."
fi

print_step "Configuring Oh-My-Zsh theme and plugins..."
if [ -f "$HOME/.zshrc" ]; then
    # Backup existing .zshrc
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"

    # Set theme
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="pmcgee"/' "$HOME/.zshrc"

    # Set plugins
    sed -i 's/^plugins=.*/plugins=(git sudo common-aliases z)/' "$HOME/.zshrc"

    print_step "Oh-My-Zsh configured with pygmalion theme and plugins: git, sudo, common-aliases, z"
else
    print_error ".zshrc not found!"
    exit 1
fi

print_step "Setting zsh as default shell..."
sudo chsh -s "$(which zsh)" "$USER"

# =============================================================================
# STEP 5: Download and install nvim config
# =============================================================================
print_step "Installing nvim configuration..."
cd "$HOME"

if [ -d "nvimbu" ]; then
    print_warning "nvimbu directory already exists, removing..."
    rm -rf nvimbu
fi

print_step "Cloning nvim config from GitHub..."
git clone https://github.com/martinshields/nvimbu.git

print_step "Backing up and installing nvim config..."
rm -rf ~/.config/nvim ~/.config/nvim.bak

if [ -d "nvimbu/nvim" ]; then
    mkdir -p ~/.config
    cp -r nvimbu/nvim ~/.config/nvim
    print_step "Nvim config installed successfully"
else
    print_error "nvimbu/nvim directory not found in cloned repo!"
    exit 1
fi

# =============================================================================
# STEP 6: Copy alias_pi.zsh and docker-compose.yaml
# =============================================================================
print_step "Copying alias_pi.zsh to Oh-My-Zsh custom folder..."
if [ -f "$SCRIPT_DIR/configs/alias_pi.zsh" ]; then
    cp "$SCRIPT_DIR/configs/alias_pi.zsh" ~/.oh-my-zsh/custom/alias_pi.zsh
    print_step "alias_pi.zsh copied successfully"
else
    print_error "alias_pi.zsh not found in $SCRIPT_DIR/configs"
    exit 1
fi

print_step "Configuring vifm to use neovim..."
if [ -f ~/.config/vifm/vifmrc ]; then
    sed -i 's/set vicmd=vim/set vicmd=nvim/g' ~/.config/vifm/vifmrc
    print_step "vifmrc updated to use neovim"
else
    print_warning "vifmrc not found, skipping..."
fi

print_step "Copying docker-compose.yaml to /opt/media-docker..."
COMPOSE_PATH="/opt/media-docker"
sudo mkdir -p "$COMPOSE_PATH"
sudo chown -R "$USER:$(id -gn)" "$COMPOSE_PATH"

if [ -f "$SCRIPT_DIR/configs/docker-compose.yaml" ]; then
    cp "$SCRIPT_DIR/configs/docker-compose.yaml" "$COMPOSE_PATH/docker-compose.yaml"
    print_step "docker-compose.yaml copied to $COMPOSE_PATH"
else
    print_error "docker-compose.yaml not found in $SCRIPT_DIR/configs"
    exit 1
fi

# =============================================================================
# STEP 7: Run pi-foldersetup.sh
# =============================================================================
print_step "Running pi-foldersetup.sh..."
if [ -f "$SCRIPT_DIR/configs/pi-foldersetup.sh" ]; then
    bash "$SCRIPT_DIR/configs/pi-foldersetup.sh"
else
    print_error "pi-foldersetup.sh not found in $SCRIPT_DIR/configs/"
    exit 1
fi

# =============================================================================
# Create setup completion documentation
# =============================================================================
print_step "Creating setup documentation..."

# Get local IP address for documentation
LOCAL_IP=$(hostname -I | awk '{print $1}')
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

cat > "$SCRIPT_DIR/setupcomplete.md" << EOF
# Raspberry Pi Media Server Setup Complete

## Installation Summary

Your Raspberry Pi has been configured with the following:

### Installed Packages
- **System Tools**: htop, fastfetch, vifm, lazygit, lazydocker
- **Development**: neovim (v0.11.2+), git, build-essential, cmake
- **Shell**: zsh with Oh-My-Zsh (pmcgee theme)
- **Docker**: docker.io, docker-compose
- **Utilities**: fzf, bat, p7zip-full, wget, curl, speedtest-cli

### Configurations Applied
- ✅ Neovim config installed from martinshields/nvimbu
- ✅ Zsh set as default shell with custom aliases
- ✅ Vifm configured to use neovim
- ✅ Docker compose stack copied to /opt/media-docker
- ✅ Storage structure created at /mnt/storage
- ✅ User added to docker, media, and downloaders groups

## Next Steps

1. **Log out and back in** for group changes to take effect
2. **Edit VPN credentials** in `/opt/media-docker/docker-compose.yaml`
   - Set OPENVPN_USER
   - Set OPENVPN_PASSWORD
3. **Change Pi-hole password** in docker-compose.yaml (WEBPASSWORD)
4. **Start services**:
   ```bash
   cd /opt/media-docker
   docker compose up -d
   ```

## Web Interfaces

Once services are running, access them at:

| Service   | URL                              | Purpose                          |
|-----------|----------------------------------|----------------------------------|
| Jellyfin  | http://$LOCAL_IP:8096            | Media streaming server           |
| Sonarr    | http://$LOCAL_IP:8989            | TV show automation               |
| Radarr    | http://$LOCAL_IP:7878            | Movie automation                 |
| Portainer | http://$LOCAL_IP:9000            | Docker container management      |
| Pi-hole   | http://$LOCAL_IP/admin           | DNS ad-blocker                   |
| Deluge    | http://$LOCAL_IP:8112            | Torrent client (via gluetun VPN) |

## Storage Structure

```
/mnt/storage/
├── downloads/
│   ├── torrents/{movies,tv,music,books}
│   └── usenet/{movies,tv,music,books}
└── medialibrary/{movies,tv,music,books}
```

## Docker Services

- **gluetun**: VPN container (Private Internet Access)
- **deluge**: Torrent client (running through gluetun network)
- **jellyfin**: Media server
- **sonarr**: TV show management
- **radarr**: Movie management
- **pihole**: Network-wide ad blocking
- **portainer**: Docker web UI
- **watchtower**: Automatic container updates

## Useful Commands

### Docker Management
```bash
# View running containers
docker ps

# View logs
docker logs -f <container_name>

# Restart a service
docker compose restart <service_name>

# Stop all services
docker compose down

# Update and restart all services
docker compose pull && docker compose up -d
```

### Storage Management
```bash
# Check mount
mountpoint /mnt/storage

# Manually repair storage structure
sudo /usr/local/bin/repair_storage_structure.sh
```

### System Info
```bash
# Quick system overview
fastfetch

# Interactive process monitor
htop

# Docker container manager
lazydocker

# File manager
vifm

# Speed test
speedtest-cli
```

## Custom Aliases (alias_pi.zsh)

- `up` - Update and upgrade system packages
- `vim`, `vi` - Aliased to neovim
- `v` - Open vifm file manager
- `myip` - Display public IP address
- `ports` - Show listening ports
- Navigation: `..`, `...`, `....`

## Troubleshooting

### Services won't start
- Check VPN credentials in docker-compose.yaml
- Verify /mnt/storage is mounted: `mountpoint /mnt/storage`
- Check logs: `docker logs <container_name>`

### Permission issues
- Ensure you logged out and back in after setup
- Verify group membership: `groups`
- Run storage repair: `sudo /usr/local/bin/repair_storage_structure.sh`

### Deluge not accessible
- Deluge shares gluetun's network, access via port 8112
- Check gluetun is running: `docker ps | grep gluetun`
- Verify VPN connection: `docker logs gluetun`

## File Locations

- Docker compose: `/opt/media-docker/docker-compose.yaml`
- Storage mount: `/mnt/storage`
- Neovim config: `~/.config/nvim`
- Zsh config: `~/.zshrc`
- Custom aliases: `~/.oh-my-zsh/custom/alias_pi.zsh`
- Vifm config: `~/.config/vifm/vifmrc`

---

Generated by runsetup.sh on $(date)
EOF

print_step "Setup documentation created at $SCRIPT_DIR/setupcomplete.md"

# =============================================================================
# COMPLETION
# =============================================================================

# Get local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Raspberry Pi Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in for group changes to take effect"
echo "  2. Your default shell is now zsh (will be active after re-login)"
echo "  3. Edit $COMPOSE_PATH/docker-compose.yaml with your VPN credentials"
echo "  4. Change Pi-hole password in docker-compose.yaml"
echo "  5. Start services: cd $COMPOSE_PATH && docker compose up -d"
echo ""
echo "Web Interface Access (after starting services):"
echo "  Jellyfin:  http://$LOCAL_IP:8096"
echo "  Sonarr:    http://$LOCAL_IP:8989"
echo "  Radarr:    http://$LOCAL_IP:7878"
echo "  Portainer: http://$LOCAL_IP:9000"
echo "  Pi-hole:   http://$LOCAL_IP/admin"
echo "  Deluge:    http://$LOCAL_IP:8112 (via gluetun)"
echo ""
echo "To start using zsh now, run: exec zsh"
echo ""
echo "Full setup details saved to: $SCRIPT_DIR/setupcomplete.md"
echo ""
