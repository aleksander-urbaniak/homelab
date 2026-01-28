# 🛠️ Manual VM Preparation Guide

This guide walks you through the **manual steps** required to prepare a new Linux Virtual Machine. It mirrors the setup automated by the `ansible/playbooks/ultimate-linux-setup.yml` playbook.

The goal is to create a **clean, standardized server environment** with solid defaults for **monitoring 📈, logging 📜, and security 🔐**.

**Supported distribution families:**

* 🟥 **RHEL-based**: CentOS, Rocky Linux, AlmaLinux, Oracle Linux 9/10
* 🟦 **Debian-based**: Ubuntu, Debian

---

## 1️⃣ Initial System & Repository Setup

### 1.1. Update Hostname Resolution 🏷️

Ensure the system IP address is correctly mapped to its hostname and Fully Qualified Domain Name (FQDN) in `/etc/hosts`.

```bash
# Example:
# 192.0.2.100 my-server my-server.example.local
```

---

### 1.2. Enable Extra Repositories (RHEL-based) 📦

On **RHEL 9/10** and their derivatives, additional repositories are required for development and monitoring packages:

* **CRB / CodeReady Builder** (RHEL / Rocky / Alma)
* **EPEL (Extra Packages for Enterprise Linux)**

**Oracle Linux 9 / 10:**

```bash
sudo dnf config-manager --set-enabled ol9_codeready_builder || sudo dnf config-manager --set-enabled ol10_codeready_builder
sudo dnf install -y oracle-epel-release-el9 || sudo dnf install -y oracle-epel-release-el10
```

**RHEL / Rocky / Alma 9 / 10:**

```bash
sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
```

---

### 1.3. System Update and Upgrade 🔄

Always start with a fully up-to-date system.

**RHEL-based:**

```bash
sudo dnf update -y
```

**Debian-based:**

```bash
sudo apt-get update
sudo apt-get dist-upgrade -y
```

---

## 2️⃣ Package Installation

Install a baseline set of tools useful for **administration, troubleshooting, and development**.

### 2.1. Common Packages (All Distributions) 🧰

```bash
# RHEL-based
sudo dnf install -y curl unzip wget git tree htop tmux screen mc python3 python3-pip rlwrap

# Debian-based
sudo apt-get install -y curl unzip wget git tree htop tmux screen mc python3 python3-pip rlwrap
```

---

### 2.2. Distribution-Specific Packages

**RHEL-based (9 / 10):**

```bash
sudo dnf install -y tig iotop chrony pciutils usbutils smartmontools ipmitool freeipmi upower autofs xhost cronie gcc python3-devel policycoreutils-python-utils tar gzip
```

**Debian-based:**

```bash
sudo apt-get install -y tig iotop chrony pciutils usbutils smartmontools ipmitool upower autofs x11-xserver-utils cron build-essential python3-dev python3-venv
```

---

## 3️⃣ Security & User Management 🔐

### 3.1. Create an Administrative User 👤

Avoid daily work as `root`. Create a dedicated admin user instead.

```bash
# Create a generic admin user
sudo useradd -m -s /bin/bash admin

# Grant administrative privileges
# RHEL-based:
sudo usermod -aG wheel admin
# Debian-based:
sudo usermod -aG sudo admin

# Set a strong password
sudo passwd admin
```

---

### 3.2. Set a Strong Root Password 🔑

```bash
sudo passwd root
```

---

### 3.3. Harden SSH Access 🛡️

Disable direct `root` login over SSH.

1. Edit the SSH configuration:

   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
2. Set:

   ```
   PermitRootLogin no
   ```
3. Restart the SSH service:

   ```bash
   # RHEL-based
   sudo systemctl restart sshd

   # Debian-based
   sudo systemctl restart ssh
   ```

---

### 3.4. Configure System Firewalls (Optional) 🚧

For **lab or internal environments**, firewalls may be disabled. For **production**, configure them properly instead.

```bash
# RHEL-based
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Debian-based
sudo ufw disable
```

---

### 3.5. Configure SELinux (RHEL-based) 🧩

Applies to **RHEL / Rocky / Alma / Oracle Linux 9 & 10**.

Set SELinux to **permissive** mode to avoid blocking during setup.

```bash
sudo setenforce 0
```

To make it persistent, edit `/etc/selinux/config` and set:

```bash
SELINUX=permissive
```

---

## 4️⃣ Shell & System Configuration ⚙️

### 4.1. Timestamped Shell History 🕒

Enable timestamps in Bash history for all users.

```bash
echo 'export HISTTIMEFORMAT="%d-%m-%Y %T "' | sudo tee /etc/profile.d/history-timestamp.sh
sudo chmod 755 /etc/profile.d/history-timestamp.sh
```

---

### 4.2. Configure Time Synchronization (Chrony) ⏱️

Accurate time is critical for logs, monitoring, and security tools.

1. Edit the Chrony configuration file:

   * RHEL: `/etc/chrony.conf`
   * Debian: `/etc/chrony/chrony.conf`

2. Replace existing `pool` / `server` entries with:

   ```
   pool 0.pool.ntp.org iburst
   pool 1.pool.ntp.org iburst
   pool 2.pool.ntp.org iburst
   ```

3. Restart the service:

   ```bash
   # RHEL-based
   sudo systemctl restart chronyd

   # Debian-based
   sudo systemctl restart chrony
   ```

---

## 5️⃣ Monitoring & Logging Agent Installation 📊

### 5.1. Prometheus Node Exporter

Exposes system and hardware metrics to Prometheus.

1. **Create service user:**

   ```bash
   sudo useradd --no-create-home --shell /bin/false node_exporter
   ```

2. **Download and install:**

   ```bash
   VERSION="1.7.0"  # Check for the latest version
   wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz
   tar xvf node_exporter-${VERSION}.linux-amd64.tar.gz
   sudo mv node_exporter-${VERSION}.linux-amd64/node_exporter /usr/local/bin/
   rm -rf node_exporter-${VERSION}.linux-amd64*
   ```

3. **Create systemd service** at `/etc/systemd/system/node_exporter.service`:

   ```ini
   [Unit]
   Description=Node Exporter
   After=network.target

   [Service]
   User=node_exporter
   Group=node_exporter
   Type=simple
   ExecStart=/usr/local/bin/node_exporter

   [Install]
   WantedBy=multi-user.target
   ```

4. **Enable and start:**

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now node_exporter
   ```

---

### 5.2. Promtail (Loki Log Shipper) 📜

Ships system logs to a Grafana Loki instance.

1. **Download and install:**

   ```bash
   VERSION="2.9.1"
   wget https://github.com/grafana/loki/releases/download/v${VERSION}/promtail-linux-amd64.zip
   unzip promtail-linux-amd64.zip
   sudo mv promtail-linux-amd64 /usr/local/bin/promtail
   rm promtail-linux-amd64.zip
   ```

2. **Create configuration directory and file:**

   ```bash
   sudo mkdir -p /etc/promtail
   sudo nano /etc/promtail/promtail-config.yaml
   ```

   ```yaml
   server:
     http_listen_port: 9080
     grpc_listen_port: 0

   positions:
     filename: /tmp/positions.yaml

   clients:
     - url: http://<LOKI_IP>:3100/loki/api/v1/push

   scrape_configs:
     - job_name: varlogs
       static_configs:
         - targets: [localhost]
           labels:
             job: varlogs
             host: ${HOSTNAME}
             __path__: /var/log/*log
   ```

3. **Create systemd service** at `/etc/systemd/system/promtail.service`:

   ```ini
   [Unit]
   Description=Promtail log shipper
   After=network-online.target

   [Service]
   Type=simple
   Environment=HOSTNAME=%H
   ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yaml -config.expand-env=true
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

4. **Enable and start:**

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now promtail
   ```

---

### 5.3. Wazuh Agent (SIEM) 🧠

Forwards security events to a central Wazuh manager.

1. **Download and install:**

   ```bash
   # RHEL-based
   wget https://packages.wazuh.com/4.x/yum/wazuh-agent-4.x.x-1.x86_64.rpm
   sudo WAZUH_MANAGER="<MANAGER_IP>" rpm -ihv wazuh-agent-4.x.x-1.x86_64.rpm

   # Debian-based
   wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.x.x-1_amd64.deb
   sudo WAZUH_MANAGER="<MANAGER_IP>" dpkg -i wazuh-agent_4.x.x-1_amd64.deb
   ```

2. **Enable and start the agent:**

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now wazuh-agent
   ```
