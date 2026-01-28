#!/usr/bin/env bash

# Output report file configuration (includes hostname and timestamp)
HOSTNAME_INFO=$(hostname)
DATE_INFO=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="system_info_${HOSTNAME_INFO}_${DATE_INFO}.txt"

# Helper function to check command availability in $PATH
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to check if a service or command exists
# First, check whether a systemd service with the given name exists
# Then, check whether a command with the given name exists.
check_service_or_command() {
    local SERVICE_NAME="$1"
    local CMD_NAME="$2"

    # Check systemd service existence (only if systemctl is available)
    if check_command systemctl; then
        # list-unit-files shows registered services
        if systemctl list-unit-files --type=service 2>/dev/null | grep -q "^${SERVICE_NAME}\.service"; then
            echo "${SERVICE_NAME}: found (systemd service)"
            return
        fi
    fi

    # Command availability check
    if [ -n "$CMD_NAME" ] && check_command "$CMD_NAME"; then
        echo "${SERVICE_NAME} (${CMD_NAME}): found (command)"
    else
        echo "${SERVICE_NAME}: not found"
    fi
}

# Create or truncate the output file
: > "$OUTPUT_FILE"

echo "====================================" >> "$OUTPUT_FILE"
echo "GENERAL INFORMATION" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

# Hostname and distribution
echo "Hostname: $HOSTNAME_INFO" >> "$OUTPUT_FILE"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribution: $NAME $VERSION" >> "$OUTPUT_FILE"
else
    if check_command lsb_release; then
        echo "Distribution: $(lsb_release -d | cut -f2)" >> "$OUTPUT_FILE"
    else
        echo "Distribution: Unable to detect" >> "$OUTPUT_FILE"
    fi
fi

# Kernel version
echo "Kernel version: $(uname -r)" >> "$OUTPUT_FILE"

# Virtualization / platform info
if check_command dmidecode; then
    echo "Virtualization:" >> "$OUTPUT_FILE"
    sudo dmidecode -s system-manufacturer >> "$OUTPUT_FILE" 2>/dev/null
    sudo dmidecode -s system-product-name >> "$OUTPUT_FILE" 2>/dev/null
fi

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "RESOURCE PARAMETERS" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

# Memory (RAM)
echo "Memory (RAM):" >> "$OUTPUT_FILE"
free -h >> "$OUTPUT_FILE"

# CPU
echo "" >> "$OUTPUT_FILE"
echo "CPU information:" >> "$OUTPUT_FILE"
if check_command lscpu; then
    lscpu >> "$OUTPUT_FILE"
else
    cat /proc/cpuinfo >> "$OUTPUT_FILE"
fi

# Disks
echo "" >> "$OUTPUT_FILE"
echo "Disk information (lsblk):" >> "$OUTPUT_FILE"
lsblk >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Disk usage (df -h):" >> "$OUTPUT_FILE"
df -h >> "$OUTPUT_FILE"

# Network
echo "" >> "$OUTPUT_FILE"
echo "Network configuration:" >> "$OUTPUT_FILE"
if check_command ip; then
    ip addr show >> "$OUTPUT_FILE"
else
    ifconfig >> "$OUTPUT_FILE"
fi

# Firewall
echo "" >> "$OUTPUT_FILE"
echo "Firewall:" >> "$OUTPUT_FILE"
if check_command nft; then
    nft list ruleset >> "$OUTPUT_FILE" 2>/dev/null
elif check_command iptables; then
    iptables -L -n -v >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "No firewall information (nft/iptables not found)" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "SYSTEM CONFIGURATION" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

# Installed packages
echo "Installed packages:" >> "$OUTPUT_FILE"
if check_command dpkg; then
    dpkg -l >> "$OUTPUT_FILE"
elif check_command rpm; then
    rpm -qa >> "$OUTPUT_FILE"
else
    echo "No package manager (dpkg/rpm) found" >> "$OUTPUT_FILE"
fi

# Repositories
echo "" >> "$OUTPUT_FILE"
echo "Repository configuration:" >> "$OUTPUT_FILE"
if [ -f /etc/apt/sources.list ]; then
    echo "/etc/apt/sources.list:" >> "$OUTPUT_FILE"
    cat /etc/apt/sources.list >> "$OUTPUT_FILE" 2>/dev/null
    echo "" >> "$OUTPUT_FILE"
    if [ -d /etc/apt/sources.list.d ]; then
        echo "Files in /etc/apt/sources.list.d:" >> "$OUTPUT_FILE"
        cat /etc/apt/sources.list.d/* >> "$OUTPUT_FILE" 2>/dev/null
    fi
elif [ -d /etc/yum.repos.d ]; then
    echo "/etc/yum.repos.d:" >> "$OUTPUT_FILE"
    cat /etc/yum.repos.d/* >> "$OUTPUT_FILE" 2>/dev/null
fi

# Sysctl settings
echo "" >> "$OUTPUT_FILE"
echo "sysctl settings:" >> "$OUTPUT_FILE"
sysctl -a >> "$OUTPUT_FILE" 2>/dev/null

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "AUTHENTICATION AND SECURITY" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

# Users and groups
echo "System users:" >> "$OUTPUT_FILE"
cat /etc/passwd >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "System groups:" >> "$OUTPUT_FILE"
cat /etc/group >> "$OUTPUT_FILE"

# SELinux/AppArmor
echo "" >> "$OUTPUT_FILE"
echo "SELinux/AppArmor:" >> "$OUTPUT_FILE"
if check_command getenforce; then
    echo "SELinux: $(getenforce)" >> "$OUTPUT_FILE"
fi
if [ -f /sys/module/apparmor/parameters/enabled ]; then
    echo "AppArmor: $(cat /sys/module/apparmor/parameters/enabled)" >> "$OUTPUT_FILE"
fi

# SSH keys
echo "" >> "$OUTPUT_FILE"
echo "SSH keys (.ssh directories):" >> "$OUTPUT_FILE"
for dir in /home/*; do
    if [ -d "$dir/.ssh" ]; then
        echo "$dir/.ssh:" >> "$OUTPUT_FILE"
        ls -la "$dir/.ssh" >> "$OUTPUT_FILE"
    fi
done

# SSL/TLS certificates
echo "" >> "$OUTPUT_FILE"
echo "SSL/TLS certificates (directory: /etc/ssl):" >> "$OUTPUT_FILE"
ls -R /etc/ssl >> "$OUTPUT_FILE" 2>/dev/null

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "BACKUPS AND RESTORE" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

echo "Potential backup tools (rsync, borg, duplicity):" >> "$OUTPUT_FILE"
for tool in rsync borg duplicity; do
    if check_command $tool; then
        echo "$tool: found" >> "$OUTPUT_FILE"
    else
        echo "$tool: not found" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "MONITORING AND LOGGING" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

echo "System logs (files in /var/log):" >> "$OUTPUT_FILE"
ls -l /var/log >> "$OUTPUT_FILE" 2>/dev/null

echo "" >> "$OUTPUT_FILE"
echo "Monitoring tools (Prometheus, Nagios, Zabbix):" >> "$OUTPUT_FILE"

# Check monitoring tools: Prometheus, Nagios, Zabbix (agent, agent2, server)
# Assume standard service and binary names:
# - prometheus: service prometheus.service, binary prometheus
# - nagios: service nagios.service, binary nagios
# - zabbix-agent: service zabbix-agent.service, binary zabbix_agentd
# - zabbix-agent2: service zabbix-agent2.service, binary zabbix_agent2
# - zabbix-server: service zabbix-server.service, binary zabbix_server

check_service_or_command "prometheus" "prometheus"
check_service_or_command "nagios" "nagios"
check_service_or_command "zabbix-agent" "zabbix_agentd"
check_service_or_command "zabbix-agent2" "zabbix_agent2"
check_service_or_command "zabbix-server" "zabbix_server"

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "AUTOMATION AND CONFIG MANAGEMENT" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

for cfgtool in ansible puppet chef-client salt; do
    if check_command $cfgtool; then
        echo "$cfgtool: found" >> "$OUTPUT_FILE"
    else
        echo "$cfgtool: not found" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "Systemd services (first 15 running):" >> "$OUTPUT_FILE"
if check_command systemctl; then
    systemctl list-units --type=service --state=running --no-pager | head -n 15 >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "User crontabs:" >> "$OUTPUT_FILE"
if [ -d /var/spool/cron/crontabs ]; then
    cat /var/spool/cron/crontabs/* >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "No standard crontab location found" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "UPDATES AND PATCHING" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

# Available updates
if check_command apt; then
    echo "Updates (apt list --upgradable):" >> "$OUTPUT_FILE"
    apt list --upgradable 2>/dev/null >> "$OUTPUT_FILE"
elif check_command yum; then
    echo "Updates (yum check-update):" >> "$OUTPUT_FILE"
    yum check-update >> "$OUTPUT_FILE" 2>/dev/null
elif check_command dnf; then
    echo "Updates (dnf check-update):" >> "$OUTPUT_FILE"
    dnf check-update >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "No update information (unknown package manager)" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "OPERATIONAL NOTES (helper info)" >> "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"

echo "Diagnostic commands: top, htop, journalctl, dmesg" >> "$OUTPUT_FILE"
if check_command top; then echo "top: available" >> "$OUTPUT_FILE"; else echo "top: missing" >> "$OUTPUT_FILE"; fi
if check_command htop; then echo "htop: available" >> "$OUTPUT_FILE"; else echo "htop: missing" >> "$OUTPUT_FILE"; fi
if check_command journalctl; then echo "journalctl: available" >> "$OUTPUT_FILE"; else echo "journalctl: missing" >> "$OUTPUT_FILE"; fi
if check_command dmesg; then echo "dmesg: available" >> "$OUTPUT_FILE"; else echo "dmesg: missing" >> "$OUTPUT_FILE"; fi

echo "" >> "$OUTPUT_FILE"
echo "Additional notes:" >> "$OUTPUT_FILE"
echo "Server purpose: (fill in manually)" >> "$OUTPUT_FILE"

# Set permissive permissions (777) on the output file
chmod 777 "$OUTPUT_FILE"

echo "Scan complete. Information saved to: $OUTPUT_FILE"
