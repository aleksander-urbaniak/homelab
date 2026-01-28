#!/bin/bash

# ==============================================================================
# Universal Docker Installation Script
# Supports: Debian, Ubuntu, CentOS, Fedora, RHEL, Raspbian, Arch Linux, Manjaro, Alpine
# Architectures: AMD64 (x86_64), ARM64 (aarch64), ARMv7
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 1. Check for Root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root. Please use 'sudo $0'"
fi

# 2. Detect Package Manager and OS
detect_strategy() {
    if command -v pacman >/dev/null 2>&1; then
        echo "arch"
    elif command -v apk >/dev/null 2>&1; then
        echo "alpine"
    elif [ -f /etc/os-release ]; then
        # For Debian, Ubuntu, Fedora, CentOS, RHEL, SLES, Raspbian
        # The official get-docker script is best for these as it handles keys/repos automatically
        echo "official_script"
    else
        echo "unknown"
    fi
}

STRATEGY=$(detect_strategy)
ARCH=$(uname -m)

info "Detected Architecture: $ARCH"
info "Installation Strategy: $STRATEGY"

# 3. Installation Logic
case $STRATEGY in
    "arch")
        info "Arch Linux/Manjaro detected. Installing via pacman..."
        pacman -Sy --noconfirm
        pacman -S --noconfirm docker docker-compose
        ;;

    "alpine")
        info "Alpine Linux detected. Installing via apk..."
        # ensure community repo is enabled for some versions, though docker is usually in community
        if ! grep -q "community" /etc/apk/repositories; then
            warn "You may need to enable the community repository in /etc/apk/repositories if installation fails."
        fi
        apk update
        apk add docker docker-compose
        ;;

    "official_script")
        info "Standard Linux Distro detected. Using official Docker convenience script..."
        
        # Install prereqs for the script to run
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y curl
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y curl
        elif command -v yum >/dev/null 2>&1; then
            yum install -y curl
        elif command -v zypper >/dev/null 2>&1; then
            zypper install -y curl
        fi

        # Download and run official script
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        ;;

    *)
        error "Could not detect a supported package manager (apt, dnf, yum, pacman, apk)."
        ;;
esac

# 4. Post-Installation Configuration

info "Configuring permissions and services..."

# Enable and Start Docker Service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable docker
    systemctl start docker
    info "Systemd service started."
elif command -v rc-service >/dev/null 2>&1; then
    # OpenRC (Alpine/Gentoo)
    rc-update add docker boot
    service docker start
    info "OpenRC service started."
else
    warn "Could not detect systemd or openrc. You may need to start the docker daemon manually."
fi

# Add real user to docker group
# We try to detect the user who called sudo, otherwise fall back to 'current' user if not root
REAL_USER=${SUDO_USER:-$USER}

if [ "$REAL_USER" != "root" ]; then
    info "Adding user '$REAL_USER' to the 'docker' group..."
    
    # Check if group exists (it should after install)
    if getent group docker >/dev/null 2>&1; then
        usermod -aG docker "$REAL_USER"
        success "User added to group."
    else
        warn "Docker group does not exist. Skipping user addition."
    fi
else
    warn "Running as root user directly. Skipping adding user to docker group."
fi

# 5. Verification
echo ""
echo "=========================================="
if command -v docker >/dev/null 2>&1; then
    D_VER=$(docker --version)
    success "Docker installed successfully: $D_VER"
    echo ""
    echo -e "${YELLOW}NOTE:${NC} You may need to log out and log back in for group permissions to take effect."
    echo -e "${YELLOW}NOTE:${NC} To test, run: 'docker run hello-world'"
else
    error "Docker installation failed. Binary not found."
fi
echo "=========================================="