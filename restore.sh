#!/bin/bash
set -e

# =============================================================================
# Homelab NVR Server Restore Script
# =============================================================================
# Run this on a fresh Ubuntu install after cloning the teleclaude repo.
# Prerequisites: fresh Ubuntu 20.04+ install with internet access via DHCP.
#
# Usage:
#   git clone https://github.com/ryanjtang/teleclaude.git
#   cd teleclaude
#   sudo bash restore.sh
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAS_IP="192.168.0.24"
NAS_SHARE="$NAS_IP:/volume1/HomelabBackup"
SERVER_IP="192.168.0.20"
GATEWAY="192.168.0.1"
BACKUP_DIR="/mnt/HomelabBackup/nvr/rsync"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    err "Run as root: sudo bash restore.sh"
fi

echo ""
echo "============================================"
echo "  Homelab NVR Server Restore"
echo "============================================"
echo ""
echo "This script will:"
echo "  1. Set static IP to $SERVER_IP"
echo "  2. Mount NAS backup share"
echo "  3. Restore from the latest rsync backup"
echo "  4. Install Docker"
echo "  5. Start all services"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

# =============================================================================
# Step 1: Configure static IP
# =============================================================================
log "Configuring static IP ($SERVER_IP)..."

# Find the primary network interface (the one with default route)
PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -1)

if [ -z "$PRIMARY_IF" ]; then
    err "Could not detect primary network interface"
fi

log "Detected primary interface: $PRIMARY_IF"

# Check if netplan exists (Ubuntu 18.04+)
if command -v netplan &>/dev/null; then
    NETPLAN_FILE="/etc/netplan/01-nvr-static.yaml"
    # Remove any existing netplan configs that might conflict
    log "Writing netplan config to $NETPLAN_FILE"
    cat > "$NETPLAN_FILE" << EOF
network:
  version: 2
  ethernets:
    $PRIMARY_IF:
      dhcp4: no
      addresses:
        - $SERVER_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - 192.168.0.22
          - 192.168.0.26
          - 8.8.8.8
EOF
    netplan apply 2>/dev/null || true
    # Give network a moment to settle
    sleep 3
else
    warn "Netplan not found — configure $SERVER_IP on $PRIMARY_IF manually, then re-run."
    exit 1
fi

# Verify connectivity
log "Verifying network connectivity..."
if ! ping -c 2 -W 3 "$NAS_IP" &>/dev/null; then
    # If NAS isn't reachable, we might have lost our route. Try gateway.
    if ! ping -c 2 -W 3 "$GATEWAY" &>/dev/null; then
        err "Cannot reach gateway ($GATEWAY). Check network cable and switch port VLAN config."
    fi
    err "Cannot reach NAS ($NAS_IP). Check NAS is powered on and NFS is enabled."
fi
log "Network OK — NAS is reachable"

# =============================================================================
# Step 2: Mount NAS
# =============================================================================
log "Installing NFS client..."
apt-get update -qq && apt-get install -y nfs-common >/dev/null 2>&1

log "Mounting NAS backup share..."
mkdir -p /mnt/HomelabBackup
mount -t nfs "$NAS_SHARE" /mnt/HomelabBackup || err "Failed to mount NAS"

if [ ! -d "$BACKUP_DIR" ]; then
    err "Backup directory not found at $BACKUP_DIR"
fi

log "NAS mounted — backup found"

# Add to fstab for persistence
if ! grep -q "HomelabBackup" /etc/fstab; then
    echo "$NAS_SHARE /mnt/HomelabBackup nfs defaults,nofail 0 0" >> /etc/fstab
    log "Added NAS mount to fstab"
fi

# =============================================================================
# Step 3: Restore from rsync backup
# =============================================================================
log "Starting rsync restore (this may take a while)..."
echo ""
warn "This will overwrite system files. Last chance to cancel (Ctrl+C)."
read -p "Proceed with restore? (y/N) " -n 1 -r
echo ""
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

rsync -aAX --info=progress2 \
    --exclude='/boot/efi/*' \
    --exclude='/etc/netplan/*' \
    --exclude='/etc/fstab' \
    --exclude='/etc/hostname' \
    --exclude='/etc/machine-id' \
    "$BACKUP_DIR/" /

log "Rsync restore complete"

# =============================================================================
# Step 4: Install Docker (if not present from restore)
# =============================================================================
if ! command -v docker &>/dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ryan
    log "Docker installed"
else
    log "Docker already present"
    systemctl enable docker
    systemctl start docker
fi

# =============================================================================
# Step 5: Start all Docker services
# =============================================================================
log "Pulling and starting Docker services..."
echo ""

SERVICES=(
    homeassistant
    frigate
    vaultwarden
    uptimekuma
    omada-controller
    changedetection
    speedtest-tracker
    dockge
    portainer
    homepage
    bentopdf
)

for svc in "${SERVICES[@]}"; do
    dir="/home/ryan/$svc"
    if [ -d "$dir" ] && [ -f "$dir/docker-compose.yml" ]; then
        log "Starting $svc..."
        cd "$dir"
        docker compose pull 2>/dev/null
        docker compose up -d 2>/dev/null
        cd /home/ryan
    else
        warn "Skipping $svc — directory or compose file not found"
    fi
done

# =============================================================================
# Step 6: Verify critical services
# =============================================================================
echo ""
log "Waiting 30 seconds for services to initialize..."
sleep 30

echo ""
echo "============================================"
echo "  Service Status"
echo "============================================"
docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null
echo ""

# Check CrowdSec
if systemctl is-active --quiet crowdsec; then
    log "CrowdSec: running"
else
    warn "CrowdSec: not running — may need: systemctl start crowdsec"
fi

if systemctl is-active --quiet crowdsec-firewall-bouncer; then
    log "CrowdSec bouncer: running"
else
    warn "CrowdSec bouncer: not running — may need: systemctl start crowdsec-firewall-bouncer"
fi

echo ""
echo "============================================"
echo "  Restore Complete"
echo "============================================"
echo ""
echo "Post-restore checklist:"
echo "  1. Verify HA at http://$SERVER_IP:8123"
echo "  2. Verify Frigate at http://$SERVER_IP:8971"
echo "  3. Verify Vaultwarden at http://$SERVER_IP:80"
echo "  4. Check CrowdSec: sudo cscli metrics"
echo "  5. Verify NAS mounts: mount | grep nfs"
echo "  6. Test backup cron: sudo crontab -l"
echo "  7. Reboot to verify everything starts on boot"
echo ""
log "Done!"
