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

print_step "Installing required packages..."
sudo apt install -y \
    htop \
    lazygit \
    lazydocker \
    fastfetch \
    fzf \
    p7zip-full \
    wget \
    curl \
    speedtest-cli \
    neovim \
    bat \
    vifm \
    zsh \
    git \
    docker.io \
    docker-compose

print_step "Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# =============================================================================
# STEP 2: Install Oh-My-Zsh and configure
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
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="pygmalion"/' "$HOME/.zshrc"

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
# STEP 3: Download and install nvim config
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
# STEP 4: Copy alias_pi.zsh and docker-compose.yaml
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_step "Copying alias_pi.zsh to Oh-My-Zsh custom folder..."
if [ -f "$SCRIPT_DIR/alias_pi.zsh" ]; then
    cp "$SCRIPT_DIR/alias_pi.zsh" ~/.oh-my-zsh/custom/alias_pi.zsh
    print_step "alias_pi.zsh copied successfully"
else
    print_error "alias_pi.zsh not found in $SCRIPT_DIR"
    exit 1
fi

print_step "Copying docker-compose.yaml to /opt/media-docker..."
COMPOSE_PATH="/opt/media-docker"
sudo mkdir -p "$COMPOSE_PATH"
sudo chown -R "$USER:$(id -gn)" "$COMPOSE_PATH"

if [ -f "$SCRIPT_DIR/docker-compose.yaml" ]; then
    cp "$SCRIPT_DIR/docker-compose.yaml" "$COMPOSE_PATH/docker-compose.yaml"
    print_step "docker-compose.yaml copied to $COMPOSE_PATH"
else
    print_error "docker-compose.yaml not found in $SCRIPT_DIR"
    exit 1
fi

# =============================================================================
# STEP 5: Run pi-foldersetup.sh
# =============================================================================
print_step "Running pi-foldersetup.sh..."
if [ -f "$SCRIPT_DIR/scripts/pi-foldersetup.sh" ]; then
    bash "$SCRIPT_DIR/scripts/pi-foldersetup.sh"
else
    print_error "pi-foldersetup.sh not found in $SCRIPT_DIR/scripts/"
    exit 1
fi

# =============================================================================
# COMPLETION
# =============================================================================
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
echo "To start using zsh now, run: exec zsh"
echo ""
