---
name: Home network reference
description: Comprehensive reference of all devices, services, access methods, and architecture for Ryan's homelab
type: reference
---

# Home Network Reference

## Network Architecture

| VLAN | ID | Subnet | Gateway | Purpose |
|---|---|---|---|---|
| LAN | 1 | 192.168.0.0/24 | 192.168.0.1 | Primary network — servers, workstations |
| Camera | 10 | 192.168.10.0/24 | 192.168.10.1 | Reolink cameras (isolated) |
| IoT | 20 | 192.168.20.0/24 | 192.168.20.1 | IoT devices |
| Guest | 30 | 192.168.30.0/24 | 192.168.30.1 | Guest wifi, OpenClaw instance |
| WireGuard | - | 10.10.10.0/24 | 10.10.10.1 | VPN (UDP 51820) |

WAN: AT&T Fiber, San Jose — ~1 Gbps symmetric via DHCP on ix0.

## Key Devices

### OPNsense Firewall — 192.168.0.1
- Runs as Proxmox VM (OPNsense 26.1.5, FreeBSD)
- Web UI: port 8443 (direct) or opnsense.lintang.family (via Caddy)
- SSH: root access via key auth
- **NICs**: Intel X540-AT2 10G dual-port (PCI passthrough via VFIO, ix0/ix1)
- **Caddy** reverse proxy: handles *.lintang.family domains, dynamic DNS to Cloudflare
- **Suricata IPS**: 33 rulesets, WAN only, active blocking. Drop conversion script at 4:30 AM after rule update at 4 AM
- **CrowdSec**: v1.7.6, LAPI on 0.0.0.0:8080 (serves both OPNsense and Docker host). Console enrolled. Hub auto-update via plugin cron (1 AM daily)
- **WireGuard**: wg0, 10.10.10.1/24, client 10.10.10.5 restricted to 192.168.0.20:5500

### Docker Host (NVR Server) — 192.168.0.20
- 13th Gen Intel i7-13700HX, NVIDIA RTX 4070 (8GB), Ubuntu 20.04 LTS
- 916G NVMe, 76G used
- **NICs**: enp111s0 (192.168.0.20, primary), enp108s0 (192.168.0.27, LAN only), enp108s0.10 (192.168.10.2, camera VLAN)
- UFW enabled
- **CrowdSec**: Agent + firewall bouncer (iptables), local LAPI disabled — points to OPNsense LAPI (192.168.0.1:8080). Collections: linux, sshd, vaultwarden, home-assistant. Docker acquisition for vaultwarden and homeassistant containers
- **Backups**: Nightly rsync (2 AM) + weekly disk image (Sunday 3 AM) to NAS. Script: /home/ryan/backup.sh. Restore guide: /mnt/HomelabBackup/nvr/RESTORE.md
- **Claude Code**: Running as systemd service with Telegram channel

### Synology NAS — 192.168.0.24
- NFS exports to 192.168.0.20 and 192.168.0.27:
  - /volume1/vaultwarden-data (Vaultwarden DB)
  - /volume1/frigate-media (Frigate recordings)
  - /volume1/HomelabBackup (backups: proxmox, nvr/rsync, nvr/images, omada)
- Mounted on Docker host at /mnt/HomelabBackup via fstab
- No SSH access from this server

### Proxmox Host
- Runs OPNsense VM (and potentially others)
- IP not confirmed from LAN — managed via Proxmox web UI
- Full VM backups to NAS (HomelabBackup/proxmox)

### DNS — Pi-hole
- Primary: 192.168.0.22
- Secondary: 192.168.0.26

### Network Hardware
- **Switch**: TP-Link SG3218XP-M2 (L2, managed by Omada)
  - Ports 1-14, 17: "LAN Trunk" profile (all VLANs except WAN)
  - Ports 15, 18: WAN VLAN isolated
- **APs**: 2x TP-Link EAP670 (192.168.0.2, 192.168.0.3)
- **Omada Controller**: Docker container on NVR server (ports 8088/8043)

### Cameras
- 4x Reolink on Camera VLAN (192.168.10.x): frontreo, backreo, garagereo, masterreo
- Managed by Frigate with NVIDIA RTX 4070 GPU decoding, YOLOv9-c 640px model

## Docker Services on NVR Server

| Service | Image | Network | Key Ports | Data Storage |
|---|---|---|---|---|
| Home Assistant | ghcr.io/home-assistant/home-assistant:stable | host | 8123 | ~/homeassistant/config |
| Z-Wave JS UI | ghcr.io/zwave-js/zwave-js-ui:latest | bridge | 8091, 3000 | ~/homeassistant/zwave-js-ui-config |
| Frigate | ghcr.io/blakeblackshear/frigate:stable | host | 8971, 5000, 8554 | NFS (frigate-media), ~/frigate/config |
| Vaultwarden | vaultwarden/server:latest | bridge | 80 | NFS (vaultwarden-data) |
| Omada Controller | mbentley/omada-controller:latest | bridge | 8088, 8043, 29810-29816 | NFS (HomelabBackup/omada) |
| Uptime Kuma | louislam/uptime-kuma:latest | bridge | 3001 | ~/uptimekuma/data |
| Portainer | portainer/portainer-ce:latest | bridge | 9000, 9443 | ~/portainer |
| Speedtest Tracker | lscr.io/linuxserver/speedtest-tracker:latest | host | 80, 443 | ~/speedtest-tracker/data |
| Dockge | louislam/dockge:1 | bridge | 5100→5001 | ~/dockge/data |
| Homepage | ghcr.io/gethomepage/homepage:latest | bridge | 3000 | ~/homepage |
| Changedetection | ghcr.io/dgtlmoon/changedetection.io | bridge | 5500→5000 | ~/changedetection/data |
| Bentopdf | ghcr.io/alam00000/bentopdf:latest | bridge | 8080 | - |

## External Domains (via Cloudflare + Caddy)

- bitwarden.lintang.family → Vaultwarden (192.168.0.20:80)
- opnsense.lintang.family → OPNsense web UI (192.168.0.1:8443)
- Other *.lintang.family subdomains likely configured in Caddy on OPNsense

## What Claude Has Access To

- **SSH**: OPNsense (root@192.168.0.1) via key auth
- **Docker**: Full access on local machine (192.168.0.20)
- **NFS**: /mnt/HomelabBackup mounted from NAS
- **CrowdSec**: cscli on both OPNsense and local
- **Home Assistant MCP**: Configured (ha-mcp via uvx), available after session restart
- **Telegram**: Bot channel to Ryan

## What Claude Does NOT Have Access To

- Proxmox web UI / API (IP unknown, no SSH key)
- NAS SSH (key not authorized)
- Omada Controller API (web UI only, no CLI/API integration)
- Pi-hole admin

## Cron Jobs

### OPNsense (UI-managed)
| Schedule | Job |
|---|---|
| Daily 4 AM | Suricata rule updates |

### OPNsense (system/plugin cron.d)
| Schedule | Job |
|---|---|
| Daily 1 AM | CrowdSec hub upgrade (oscrowdsec.cron) |
| Daily 3 AM | CrowdSec hub upgrade (defers to 1 AM job) |
| Daily 4:30 AM | Suricata drop conversion + reload |
| Hourly | Syslog archive |
| Every 4 min | Gateway ping monitoring |
| Every 15 min | Expire virusprot/sshlockout PF tables (1hr) |
| Monthly 1st 3 AM | Bogon filter update |

### Docker Host (root crontab)
| Schedule | Job |
|---|---|
| Daily 2 AM | /home/ryan/backup.sh rsync |
| Sunday 3 AM | /home/ryan/backup.sh image |

## Security Stack

1. **OPNsense Firewall** — VLAN isolation, stateful packet filtering, bogon blocking
2. **Suricata IPS** — 33 rulesets, active blocking on WAN
3. **CrowdSec (OPNsense)** — Parses firewall logs, Suricata eve.json, Caddy access logs. Console enrolled
4. **CrowdSec (Docker host)** — Parses SSH auth.log, Vaultwarden/HA container logs. Shares decisions with OPNsense via shared LAPI
5. **UFW** — Host firewall on Docker server
6. **Cloudflare** — DNS proxy, DDoS protection for *.lintang.family
