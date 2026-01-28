#!/bin/bash

# --- CONFIGURATION ---
OLD_USER="user1"
NEW_USER="user2"
NEW_UID=1000
NEW_GID=1000
NEW_PASS="P@ssw0rd1233"
LOG_FILE="/var/log/migration_debug.log"

# --- SAFETY CHECKS ---
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Starting Migration at $(date) ==="

# 1. Check if we are killing Root
OLD_UID=$(id -u "$OLD_USER" 2>/dev/null)
if [[ "$OLD_UID" == "0" ]]; then
    echo "[!!!] CRITICAL ERROR: User '$OLD_USER' has UID 0 (Root)."
    echo "      Deleting this user will destroy the system/session."
    echo "      Aborting immediately."
    exit 1
fi

# 2. Check current directory
if [[ "$(pwd)" == "/home/$OLD_USER"* ]]; then
    echo "[!] You are standing in the directory you want to delete."
    echo "    Moving to /tmp to prevent session death..."
    cd /tmp
fi

# --- THE WORKER FUNCTIONS ---

echo "[*] Step 1: Cleaning up '$OLD_USER' (UID: $OLD_UID)..."

# Kill processes delicately
if command -v loginctl >/dev/null; then
    echo "    - Calling loginctl terminate-user..."
    loginctl terminate-user "$OLD_USER" 2>/dev/null || true
fi

# Kill only specific PIDs, strictly filtering out our own $$ (current script)
echo "    - identifying PIDs..."
PIDS_TO_KILL=$(pgrep -u "$OLD_USER" | grep -v $$)

if [[ -n "$PIDS_TO_KILL" ]]; then
    echo "    - Killing PIDs: $PIDS_TO_KILL"
    kill -TERM $PIDS_TO_KILL 2>/dev/null || true
    sleep 2
    kill -KILL $PIDS_TO_KILL 2>/dev/null || true
else
    echo "    - No active processes found for user."
fi

# Delete user
echo "    - Deleting user record..."
userdel -f -r "$OLD_USER" 2>/dev/null || deluser --remove-home --force "$OLD_USER" 2>/dev/null

# Check if gone
if id "$OLD_USER" >/dev/null 2>&1; then
    echo "[X] Failed to delete '$OLD_USER'. Check locks."
    exit 1
else
    echo "[V] '$OLD_USER' deleted."
fi

echo "[*] Step 2: Creating '$NEW_USER'..."

# Create Group
if ! getent group "$NEW_GID" >/dev/null; then
    groupadd -g "$NEW_GID" "$NEW_USER"
    echo "    - Group created."
else
    echo "    - Group GID exists (adjusting if needed)..."
    # logic to handle existing group omitted for safety, assuming standard migration
    groupmod -n "$NEW_USER" "$(getent group "$NEW_GID" | cut -d: -f1)" 2>/dev/null || true
fi

# Create User
if ! id "$NEW_USER" >/dev/null 2>&1; then
    useradd -m -u "$NEW_UID" -g "$NEW_GID" -s /bin/bash "$NEW_USER"
    echo "    - User created."
else
    echo "    - User exists, ensuring permissions..."
    usermod -u "$NEW_UID" -g "$NEW_GID" "$NEW_USER"
    chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER"
fi

# Set Pass & Sudo
echo "${NEW_USER}:${NEW_PASS}" | chpasswd
usermod -aG sudo "$NEW_USER" 2>/dev/null || usermod -aG wheel "$NEW_USER" 2>/dev/null

echo "=== SUCCESS ==="
echo "User '$NEW_USER' is ready."