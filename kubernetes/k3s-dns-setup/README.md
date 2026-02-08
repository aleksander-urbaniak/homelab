# 📘 K3s + CoreDNS: Cluster DNS and Private LAN DNS Together ✨

This guide fixes a K3s setup where:
- Cluster DNS works (for example, `kubernetes.default.svc.k3s.example.com`).
- Private LAN domains do not resolve from pods when using the CoreDNS service IP (for example, `gitlab.corp.example.com`).

All domains and IPs below are examples. Replace them with your environment.

## Symptoms

From a pod, these work:

```bash
nslookup kubernetes.default.svc.k3s.example.com 10.43.0.10
nslookup example.com 10.43.0.10
```

But this does not:

```bash
nslookup gitlab.corp.example.com 10.43.0.10
```

Directly querying the LAN DNS servers works:

```bash
nslookup gitlab.corp.example.com 192.0.2.10
```

## Diagnosis

CoreDNS (ConfigMap `kube-system/coredns`) typically forwards via:

```coredns
forward . /etc/resolv.conf
```

The important detail: `/etc/resolv.conf` inside the CoreDNS pod is not guaranteed to match the host. In this case it pointed at public resolvers (for example `8.8.8.8`), which do not know your private zone. That is why CoreDNS returned no answer for `gitlab.corp.example.com`.

## Goal

Pods should resolve, at the same time:
- Kubernetes service names (via the CoreDNS `kubernetes` plugin).
- Private LAN domains (via your LAN DNS servers).
- Public internet domains.

## Fix (Persistent): Set kubelet `resolv-conf`

Rather than editing CoreDNS directly (which K3s re-applies), make kubelet generate pod `/etc/resolv.conf` from your own file. Then CoreDNS forwarding stays correct and survives reboots.

## 1) Create a dedicated `resolv.conf` (all nodes)

```bash
sudo tee /etc/k3s-resolv.conf >/dev/null <<'EOF'
nameserver 192.0.2.10
nameserver 192.0.2.11
EOF
```

Tip: keep only IPv4 nameservers if you do not need IPv6 to avoid timeouts.

## 2) Configure K3s to use it (all nodes)

If the file does not exist, that is expected.

```bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<'EOF'
kubelet-arg:
  - "resolv-conf=/etc/k3s-resolv.conf"
EOF
```

## 3) Restart K3s services

Control-plane nodes:

```bash
sudo systemctl restart k3s
```

Worker nodes:

```bash
sudo systemctl restart k3s-agent
```

If you are unsure which service a node runs:

```bash
systemctl status k3s
systemctl status k3s-agent
```

## Verification

1. Cluster DNS:

```bash
kubectl run --rm -i -t dns-test --image=busybox:1.36 --restart=Never -- sh -c \
  'nslookup kubernetes.default.svc.k3s.example.com 10.43.0.10'
```

Expected result includes the Kubernetes service IP, for example `10.43.0.1`.

2. Private LAN DNS:

```bash
kubectl run --rm -i -t dns-test --image=busybox:1.36 --restart=Never -- sh -c \
  'nslookup gitlab.corp.example.com 10.43.0.10'
```

Expected result includes your private IP, for example `192.0.2.71`.

3. Public DNS (sanity check):

```bash
kubectl run --rm -i -t dns-test --image=busybox:1.36 --restart=Never -- sh -c \
  'nslookup example.com 10.43.0.10'
```

## Why Not Edit CoreDNS Directly?

K3s manages CoreDNS as an addon. Manual changes to `kube-system/coredns` are overwritten after restarts or reboots.

## Why Not `coredns-custom` With `forward . 192.0.2.10 192.0.2.11`?

The base Corefile already includes `forward . /etc/resolv.conf`. CoreDNS does not override identical `forward` blocks; you end up with multiple competing `forward .` entries and inconsistent behavior.

## Result

After applying this fix:
- Pods resolve Kubernetes service names.
- Pods resolve private LAN domains via your LAN DNS servers.
- Pods resolve public internet domains.
- The change survives reboots.
