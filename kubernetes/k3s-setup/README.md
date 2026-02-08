# 📘 K3s Install on RHEL ✨

This guide sets up a highly available K3s cluster on RHEL-based systems with:
- 3 control-plane nodes
- 3 worker nodes
- 3 Longhorn nodes
- kube-vip for a virtual IP (VIP)

## Cluster Inventory

| Role | Hostname | IP |
| --- | --- | --- |
| Master 1 | k3s-master-1 | 192.0.2.40 |
| Master 2 | k3s-master-2 | 192.0.2.41 |
| Master 3 | k3s-master-3 | 192.0.2.42 |
| Worker 1 | k3s-worker-1 | 192.0.2.50 |
| Worker 2 | k3s-worker-2 | 192.0.2.51 |
| Worker 3 | k3s-worker-3 | 192.0.2.52 |
| Longhorn 1 | longhorn-1 | 192.0.2.60 |
| Longhorn 2 | longhorn-2 | 192.0.2.61 |
| Longhorn 3 | longhorn-3 | 192.0.2.62 |

## Variables

```bash
MASTER_NODE1_HOSTNAME="k3s-master-1"
MASTER_NODE1_IP="192.0.2.40"
MASTER_NODE2_HOSTNAME="k3s-master-2"
MASTER_NODE2_IP="192.0.2.41"
MASTER_NODE3_HOSTNAME="k3s-master-3"
MASTER_NODE3_IP="192.0.2.42"
WORKER_NODE1_HOSTNAME="k3s-worker-1"
WORKER_NODE1_IP="192.0.2.50"
WORKER_NODE2_HOSTNAME="k3s-worker-2"
WORKER_NODE2_IP="192.0.2.51"
WORKER_NODE3_HOSTNAME="k3s-worker-3"
WORKER_NODE3_IP="192.0.2.52"
LONGHORN_NODE1_HOSTNAME="longhorn-1"
LONGHORN_NODE1_IP="192.0.2.60"
LONGHORN_NODE2_HOSTNAME="longhorn-2"
LONGHORN_NODE2_IP="192.0.2.61"
LONGHORN_NODE3_HOSTNAME="longhorn-3"
LONGHORN_NODE3_IP="192.0.2.62"
```

## 0) Add Hosts Entries (All Nodes)

```bash
sudo tee -a /etc/hosts <<EOF
${MASTER_NODE1_IP} ${MASTER_NODE1_HOSTNAME}
${MASTER_NODE2_IP} ${MASTER_NODE2_HOSTNAME}
${MASTER_NODE3_IP} ${MASTER_NODE3_HOSTNAME}
${WORKER_NODE1_IP} ${WORKER_NODE1_HOSTNAME}
${WORKER_NODE2_IP} ${WORKER_NODE2_HOSTNAME}
${WORKER_NODE3_IP} ${WORKER_NODE3_HOSTNAME}
${LONGHORN_NODE1_IP} ${LONGHORN_NODE1_HOSTNAME}
${LONGHORN_NODE2_IP} ${LONGHORN_NODE2_HOSTNAME}
${LONGHORN_NODE3_IP} ${LONGHORN_NODE3_HOSTNAME}
EOF
sudo chattr +i /etc/hosts
```

## 1) Prepare All Nodes

### Update and install packages

```bash
sudo dnf makecache; dnf up -y
sudo dnf install -y apt-transport-https ca-certificates curl gnupg lsb-release git net-tools
```

### Disable swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### Disable SELinux (requires reboot)

```bash
sudo bash -c 'cp -a /etc/selinux/config{,.bak}; sed -ri "s/^SELINUX=.*/SELINUX=disabled/" /etc/selinux/config; setenforce 0 || true'
sudo reboot
```

## 2) Initialize First Master Node

```bash
export K3S_TOKEN=REPLACE_ME
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --cluster-domain=k3s.example.com \
  --tls-san=192.0.2.70 \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --advertise-address=$(hostname -I | awk '{print $1}') \
  --disable=traefik \
  --disable servicelb \
  --flannel-iface=ens18 \
  --node-taint="CriticalAddonsOnly=true:NoExecute"
```

### Add K3s to PATH and verify

```bash
echo 'export PATH=$PATH:/usr/local/bin' | sudo tee /etc/profile.d/k3s.sh
source /etc/profile.d/k3s.sh
k3s kubectl get nodes
```

### Configure kubeconfig

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Install kube-vip (VIP)

```bash
export vip=192.0.2.70
export interface=ens18
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/kube-vip
cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > kube-vip.yaml
sudo mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
systemctl restart k3s
```

## 3) Add Other Master Nodes

```bash
export K3S_TOKEN=REPLACE_ME
curl -sfL https://get.k3s.io | sh -s - server \
  --server=https://192.0.2.70:6443 \
  --cluster-domain=k3s.example.com \
  --tls-san=192.0.2.70 \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --advertise-address=$(hostname -I | awk '{print $1}') \
  --disable=traefik \
  --disable servicelb \
  --flannel-iface=ens18 \
  --node-taint="CriticalAddonsOnly=true:NoExecute"
```

## 4) Add Worker Nodes

```bash
export K3S_TOKEN=REPLACE_ME
curl -sfL https://get.k3s.io | sh -s - agent \
  --server=https://192.0.2.70:6443 \
  --token=$K3S_TOKEN \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --node-name=$(hostname)
```
