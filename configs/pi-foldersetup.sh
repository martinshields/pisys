
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

MOUNT_POINT="/mnt/storage"
BASE="${MOUNT_POINT}"
COMPOSE_PATH="/opt/media-docker"
REPAIR_SCRIPT="/usr/local/bin/repair_storage_structure.sh"
SYSTEMD_SERVICE="/etc/systemd/system/storage-repair.service"

# Ensure mount exists
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "⚠️  $MOUNT_POINT is not mounted."
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL
    echo ""

    read -p "Enter the device to mount to $MOUNT_POINT (e.g., sda1, nvme0n1p1) or 'skip' to exit: " DEVICE

    if [ "$DEVICE" = "skip" ] || [ -z "$DEVICE" ]; then
        echo "❌ Exiting. Mount your storage drive to $MOUNT_POINT and re-run this script."
        exit 1
    fi

    echo "📂 Creating $MOUNT_POINT directory..."
    sudo mkdir -p "$MOUNT_POINT"

    echo "💾 Mounting /dev/$DEVICE to $MOUNT_POINT..."
    if sudo mount /dev/$DEVICE "$MOUNT_POINT"; then
        echo "✅ Successfully mounted /dev/$DEVICE to $MOUNT_POINT"

        # Ask about fstab
        read -p "Add this mount to /etc/fstab for automatic mounting on boot? (y/n): " ADD_FSTAB
        if [ "$ADD_FSTAB" = "y" ]; then
            FSTYPE=$(lsblk -no FSTYPE /dev/$DEVICE)
            UUID=$(sudo blkid -s UUID -o value /dev/$DEVICE)

            if [ -n "$UUID" ]; then
                # Check if already in fstab
                if grep -q "$UUID" /etc/fstab 2>/dev/null; then
                    echo "⚠️  UUID $UUID already exists in /etc/fstab, skipping..."
                else
                    FSTAB_ENTRY="UUID=$UUID $MOUNT_POINT $FSTYPE defaults 0 2"
                    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
                    echo "✅ Added to /etc/fstab: $FSTAB_ENTRY"
                fi
            else
                echo "❌ Could not determine UUID for /dev/$DEVICE"
            fi
        fi
    else
        echo "❌ Failed to mount /dev/$DEVICE"
        exit 1
    fi
else
    echo "✅ Drive detected at $MOUNT_POINT"
fi

# Create folder structure
echo "📁 Creating directory structure..."
sudo mkdir -p "$BASE/downloads/torrents/movies"
sudo mkdir -p "$BASE/downloads/torrents/music"
sudo mkdir -p "$BASE/downloads/torrents/books"
sudo mkdir -p "$BASE/downloads/torrents/tv"

sudo mkdir -p "$BASE/downloads/usenet/movies"
sudo mkdir -p "$BASE/downloads/usenet/music"
sudo mkdir -p "$BASE/downloads/usenet/books"
sudo mkdir -p "$BASE/downloads/usenet/tv"

sudo mkdir -p "$BASE/medialibrary/movies"
sudo mkdir -p "$BASE/medialibrary/music"
sudo mkdir -p "$BASE/medialibrary/books"
sudo mkdir -p "$BASE/medialibrary/tv"

sudo mkdir -p /opt/media-docker/pihole/etc-pihole
sudo mkdir -p /opt/media-docker/pihole/etc-dnsmasq.d

echo "📁 Folder structure created."

# Groups
echo "👥 Creating groups..."
sudo groupadd -f media
sudo groupadd -f downloaders

echo "➕ Adding $USER to groups..."
sudo usermod -aG media "$USER"
sudo usermod -aG downloaders "$USER"

if id deluge &>/dev/null; then
    sudo usermod -aG downloaders deluge
fi

# Ask for permissions
echo ""
echo "🔐 Choose folder permissions:"
echo "1) 700  (user only)"
echo "2) 770  (user + media group) [Recommended]"
echo "3) 777  (everyone full access)"
echo "4) 775  (standard media server)"
read -p "Enter choice (1–4) [default 2]: " perm_choice
perm_choice=${perm_choice:-2}

case $perm_choice in
    1) perms="700" ;;
    3) perms="777" ;;
    4) perms="775" ;;
    *) perms="770" ;;
esac

HOST_UID=$(id -u)
HOST_GID=$(getent group media | awk -F: '{print $3}')
[ -z "$HOST_GID" ] && HOST_GID=$(id -g)

echo "🔧 Applying permissions ($perms)..."
sudo chown -R "$USER:media" "$BASE"
sudo chmod -R "$perms" "$BASE"

# Sticky bit
echo "📎 Applying sticky-bit protections..."
sudo chmod +t "$BASE/downloads"
sudo chmod +t "$BASE/downloads/torrents"
sudo chmod +t "$BASE/downloads/usenet"

# Auto-repair script
echo "🛠 Creating auto-repair script..."
sudo tee "$REPAIR_SCRIPT" >/dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
BASE="$BASE"

paths=(
  "\$BASE/downloads/torrents/movies"
  "\$BASE/downloads/torrents/music"
  "\$BASE/downloads/torrents/books"
  "\$BASE/downloads/torrents/tv"
  "\$BASE/downloads/usenet/movies"
  "\$BASE/downloads/usenet/music"
  "\$BASE/downloads/usenet/books"
  "\$BASE/downloads/usenet/tv"
  "\$BASE/medialibrary/movies"
  "\$BASE/medialibrary/music"
  "\$BASE/medialibrary/books"
  "\$BASE/medialibrary/tv"
)

for p in "\${paths[@]}"; do
    [ -d "\$p" ] || mkdir -p "\$p"
done

chown -R $USER:media "\$BASE"
chmod -R $perms "\$BASE"
EOF

sudo chmod +x "$REPAIR_SCRIPT"

# Systemd service
echo "🛠 Creating systemd repair service..."
sudo tee "$SYSTEMD_SERVICE" >/dev/null <<EOF
[Unit]
Description=Repair storage folder structure on boot
After=local-fs.target

[Service]
Type=oneshot
ExecStart=$REPAIR_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable storage-repair.service

# Create compose directory
sudo mkdir -p "$COMPOSE_PATH"
sudo chown -R "$USER:$(id -gn)" "$COMPOSE_PATH"

echo ""
echo "🎉 Setup complete!"
echo "Your Docker compose folder: $COMPOSE_PATH"
echo "Now place docker-compose.yml there."

