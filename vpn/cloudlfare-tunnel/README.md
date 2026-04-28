# 🌐 Cloudflare Tunnel + WARP Private Network Access

This runbook documents how to use Cloudflare Zero Trust as remote access for private homelab subnets (VPN-like access through WARP), consistent with this repository's networking model.

## Scope in this repository

- Networking model reference: `networking/README.md`
- K3s connector deployment: `kubernetes/applications/manifests/cloudflared/`
- Docker connector deployment: `docker/applications/cloudflared/`
- WireGuard alternative: `vpn/wireguard/README.md`

Use this document for tunnel routing, Access policies, and WARP client profile setup.

## Example variables

Replace with your own values.

```bash
TEAM_NAME=example-team
TUNNEL_NAME=homelab-tunnel
PRIVATE_CIDR=192.0.2.0/24
ADMIN_EMAIL=admin@example.com
LOCAL_DNS_DOMAIN=lab.example.com
LOCAL_DNS_SERVER=192.0.2.53
TEST_HOST=192.0.2.1
```

## 1) Create and run the tunnel connector

Choose one connector method.

### Option A: Zero Trust dashboard wizard

Use this path in Zero Trust:

1. Go to `Networks -> Connectors -> Cloudflare Tunnels`.
2. Click `Create a tunnel` and choose `Cloudflared`.
3. Name the tunnel (for example `homelab-tunnel`) and install connector on your host.
4. In tunnel setup, open the `CIDR` tab and add your private route (for example `192.0.2.0/24`).
5. Save and confirm tunnel status is `Healthy`.

### Wizard flow for devices (from onboarding UI)

If you use the onboarding card shown in your screenshots (`Connect a device to private network` -> `Add a device`), use this step mapping:

1. `Download WARP`
   - Select OS and install the WARP client.
2. `Define enrollment policies`
   - Allow only approved identities (for example `@example.com` users or specific groups).
3. `Select service mode`
   - Use `Gateway with WARP` for private network access through Tunnel.
4. `Set default routing`
   - Keep defaults unless you have a strict requirement.
5. `Manage split tunnels`
   - Ensure your private CIDR is routed through WARP.
   - If you use `Exclude IPs and domains`, remove your private CIDR from the exclude list.
6. `Complete WARP installation`
   - User signs in to your team in the WARP app and connects.
7. `Review details`
   - Confirm device enrollment, profile assignment, and routing.

### Option B: Kubernetes connector (recommended for this repo)

1. Create tunnel token in Cloudflare Zero Trust.
2. Put token in `kubernetes/applications/manifests/cloudflared/cloudflared-secrets.yml`.
3. Deploy:

```bash
kubectl apply -f kubernetes/applications/manifests/cloudflared/cloudflared-manifest.yml
kubectl -n cloudflared get pods
```

### Option C: Docker connector

1. Create tunnel token in Cloudflare Zero Trust.
2. Put token in `docker/applications/cloudflared/.env` as `TUNNEL_TOKEN`.
3. Start stack:

```bash
docker compose -f docker/applications/cloudflared/compose.yml up -d
docker compose -f docker/applications/cloudflared/compose.yml logs -f
```

### Option D: Native CLI

```bash
cloudflared tunnel login
cloudflared tunnel create <TUNNEL_NAME>
cloudflared tunnel route ip add <PRIVATE_CIDR> <TUNNEL_NAME>
cloudflared tunnel run <TUNNEL_NAME>
```

If using CLI config file mode, ensure `warp-routing` is enabled:

```yaml
tunnel: <TUNNEL_UUID>
credentials-file: /root/.cloudflared/<TUNNEL_UUID>.json
warp-routing:
  enabled: true
```

## 2) Add private network route

In `Zero Trust -> Networks -> Tunnels -> <your tunnel> -> Private networks`, add:

- CIDR: `192.0.2.0/24` (or your subnet)

Equivalent CLI:

```bash
cloudflared tunnel route ip add 192.0.2.0/24 <TUNNEL_NAME>
```

## 3) Create Access policy for private network

1. Go to `Access -> Applications -> Add an application`.
2. Select `Private Network`.
3. Create app (for example `homelab-warp`).
4. Add policies in strict order:

- `Allow Admin`: include `admin@example.com` (or your admin identity group).
- `Allow Trusted Users`: include only approved users/groups.
- `Block All`: catch-all block at the end.

Principle: allow-list explicit identities, then block everything else.

## 4) Configure WARP device profile

Go to `Settings -> WARP Client -> Device settings` and set:

- Service mode: `Gateway with WARP` (Traffic and DNS).
- Device tunnel protocol: `WireGuard`.
- Auto connect: enabled (duration as needed).
- Allow leave organization: disabled for managed devices.

Split tunnel requirement:

- If profile mode is `Exclude IPs and domains`, remove your private CIDR from exclusions.
- If your private CIDR is excluded, traffic will bypass WARP and private access will fail.

Optional local DNS fallback:

- Domain: `lab.example.com`
- DNS server: `192.0.2.53`

## 5) Enroll client and validate

1. Install Cloudflare WARP client on endpoint.
2. Sign in with your Zero Trust team name.
3. Connect WARP.
4. Validate:

```bash
ping 192.0.2.1
nslookup service.lab.example.com
```

## Troubleshooting

- Tunnel not healthy: check connector logs and token validity.
- Private IP unreachable: verify route CIDR and split tunnel exclusions.
- Auth works but no access: review Access policy order and destination rules.
- DNS names fail: configure Local Domain Fallback to internal resolver.

## Security notes

- Keep `TUNNEL_TOKEN` in Kubernetes/Docker secrets only.
- Do not commit real tokens, emails, domains, or internal IP plans.
- Prefer group-based Access policies over individual-user rules.

## References

- https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/
- https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/private-net/cloudflared/connect-cidr/
- https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/warp/deployment/device-enrollment/
- https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/warp/configure-warp/warp-modes/
- https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/warp/configure-warp/route-traffic/split-tunnels/
