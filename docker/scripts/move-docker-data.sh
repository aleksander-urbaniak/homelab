#!/bin/bash

# ==============================================================================
# Interactive Docker Data Mover
# Safely moves Docker data-root to a new location, updates config, and cleans up.
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper Functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 1. Check Root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root. Try: sudo $0"
fi

# 2. Check Dependencies
if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed."
fi
if ! command -v rsync >/dev/null 2>&1; then
    warn "rsync not found. Installing..."
    if command -v apt-get >/dev/null; then apt-get update && apt-get install -y rsync
    elif command -v dnf >/dev/null; then dnf install -y rsync
    elif command -v yum >/dev/null; then yum install -y rsync
    elif command -v pacman >/dev/null; then pacman -S --noconfirm rsync
    elif command -v apk >/dev/null; then apk add rsync
    else error "Could not install rsync. Please install it manually."; fi
fi

# 3. Detect Current State
info "Detecting current Docker configuration..."
if ! systemctl is-active --quiet docker; then
    warn "Docker is not running. Starting it temporarily to read config..."
    systemctl start docker
    STARTED_DOCKER=true
fi

CURRENT_DIR=$(docker info --format '{{.DockerRootDir}}')
info "Current Docker Data Directory: $CURRENT_DIR"

if [ "$STARTED_DOCKER" = true ]; then
    systemctl stop docker
fi

# 4. Interactive Input
echo ""
echo -e "${YELLOW}Where would you like to move the Docker data?${NC}"
read -p "Enter new path (e.g., /mnt/storage/docker): " NEW_DIR

# Remove trailing slash
NEW_DIR=${NEW_DIR%/}

# Validation
if [ -z "$NEW_DIR" ]; then error "Path cannot be empty."; fi
if [ "$NEW_DIR" == "$CURRENT_DIR" ]; then error "New path is same as current path."; fi

# Check if parent directory exists
PARENT_DIR=$(dirname "$NEW_DIR")
if [ ! -d "$PARENT_DIR" ]; then
    error "Parent directory $PARENT_DIR does not exist. Please mount your drive first."
fi

# confirm prompt
echo ""
echo "------------------------------------------------"
echo -e "Moving data from: ${RED}$CURRENT_DIR${NC}"
echo -e "To new location:  ${GREEN}$NEW_DIR${NC}"
echo "------------------------------------------------"
read -p "Are you sure you want to proceed? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborting."
    exit 0
fi

# 5. Stop Docker
info "Stopping Docker service..."
systemctl stop docker

# 6. Copy Data with Progress
info "Copying data... This may take a while."
mkdir -p "$NEW_DIR"

# Check for rsync availability again just in case
if command -v rsync >/dev/null 2>&1; then
    # -a: archive mode, -x: don't cross filesystem boundaries, -H: preserve hard links, -A: preserve ACLs, -X: preserve xattrs
    # --info=progress2: show overall progress
    rsync -axHAX --info=progress2 "$CURRENT_DIR/" "$NEW_DIR/"
else
    # Fallback if rsync installation failed earlier for some reason
    cp -rp "$CURRENT_DIR"/* "$NEW_DIR/"
fi

if [ $? -ne 0 ]; then
    error "Data copy failed. Reverting..."
fi
success "Data copied successfully."

# 7. Update Configuration (daemon.json)
# We use a python one-liner to safely edit JSON without breaking syntax
CONFIG_FILE="/etc/docker/daemon.json"
info "Updating $CONFIG_FILE..."

if ! command -v python3 >/dev/null 2>&1; then
    warn "Python3 not found. Attempting raw string replacement (risky)..."
    # Basic fallback
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "{ \"data-root\": \"$NEW_DIR\" }" > "$CONFIG_FILE"
    else
        # This is a bit brittle, assumes user can fix if complex
        warn "Please manually verify $CONFIG_FILE contains: \"data-root\": \"$NEW_DIR\""
        sed -i 's|"data-root": *"[^"]*"|"data-root": "'"$NEW_DIR"'"|' "$CONFIG_FILE"
        if ! grep -q "data-root" "$CONFIG_FILE"; then
             # If it wasn't there to replace, we must append. 
             # Simplest way: backup and overwrite with single config if file was simple
             cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
             echo "{\n  \"data-root\": \"$NEW_DIR\"\n}" > "$CONFIG_FILE"
             warn "Overwrote daemon.json. Original saved as .bak. Check content if you had custom settings."
        fi
    fi
else
    # Robust Python JSON handling
    python3 -c "
import json
import os
import sys

config_path = '/etc/docker/daemon.json'
new_dir = sys.argv[1]

data = {}
if os.path.exists(config_path):
    try:
        with open(config_path, 'r') as f:
            content = f.read()
            if content.strip():
                data = json.loads(content)
    except Exception as e:
        print(f'Error reading JSON: {e}')
        sys.exit(1)

data['data-root'] = new_dir

try:
    with open(config_path, 'w') as f:
        json.dump(data, f, indent=4)
except Exception as e:
    print(f'Error writing JSON: {e}')
    sys.exit(1)
" "$NEW_DIR"
fi

# 8. Start and Verify
info "Starting Docker..."
systemctl start docker

info "Verifying new root..."
ACTUAL_ROOT=$(docker info --format '{{.DockerRootDir}}')

if [ "$ACTUAL_ROOT" == "$NEW_DIR" ]; then
    success "Docker is running with new root: $ACTUAL_ROOT"
else
    error "Migration failed. Docker is using $ACTUAL_ROOT but expected $NEW_DIR. Check /etc/docker/daemon.json"
fi

# 9. Cleanup
echo ""
echo -e "${YELLOW}Migration complete.${NC}"
echo "We can now remove the old data directory to free up space."
echo -e "Old Directory: ${RED}$CURRENT_DIR${NC}"
read -p "Delete old data? (type 'delete' to confirm): " CLEANUP

if [ "$CLEANUP" == "delete" ]; then
    info "Removing old directory..."
    rm -rf "$CURRENT_DIR"
    success "Old data removed."
else
    info "Skipping cleanup. You can remove $CURRENT_DIR manually later."
fi

echo ""
success "All operations completed successfully!"