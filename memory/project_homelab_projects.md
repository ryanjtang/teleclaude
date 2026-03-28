---
name: Homelab improvement projects
description: Running list of identified homelab projects and improvements to tackle
type: project
---

## Queued Projects

### OPNsense / Network Security
- [x] **Trim Suricata rulesets** — Trimmed from 65 to 33 rulesets, removed irrelevant categories (2026-03-28). Backup at installed_rules.yaml.bak. Note: OPNsense GUI rule updates may regenerate installed_rules.yaml.
- [x] **PCI passthrough NIC to OPNsense** — Intel X540-AT2 10G dual-port passed through via VFIO. IOMMU enabled in kernel cmdline (intel_iommu=on iommu=pt). Confirmed 2026-03-28.
- [x] **Upgrade CrowdSec to v1.7.6** — Already on v1.7.6_2 as of 2026-03-28.
- [x] **CrowdSec hub auto-update cron** — Already handled by CrowdSec plugin: /usr/local/etc/cron.d/crowdsec (3 AM) and oscrowdsec.cron (1 AM). No action needed. (2026-03-28)

### CrowdSec Expansion
- [x] **Install CrowdSec agent on Docker host** — Installed via apt (not Docker) with firewall bouncer (iptables). Local LAPI disabled — agent and bouncer point at OPNsense LAPI (192.168.0.1:8080). OPNsense LAPI listen_uri changed to 0.0.0.0:8080. Collections: linux, sshd, vaultwarden, home-assistant. Docker acquisition monitors vaultwarden and homeassistant containers. Decisions shared between both hosts. (2026-03-28)

### Docker
- [x] **Docker compose cleanup** — Applied all changes (2026-03-28): Uptime Kuma TZ fix + removed version; zwave-js-ui removed privileged; Frigate removed Coral device + redundant ports; Speedtest removed empty DB vars; Omada migrated to NFS on NAS (HomelabBackup/omada). Kept changedetection comments and chrome processes at 10. Dockge mount left as-is.
- [x] **Pin critical Docker images** — Decided not to pin; auto-update cron already removed (2026-03-27) so images only update on manual pull. Current versions as of 2026-03-28: Vaultwarden 1.35.4, Home Assistant 2026.3.4, Z-Wave JS UI 11.15.1.

### General
- [x] **OPNsense config backup strategy** — Covered by Proxmox full VM backup to NAS. (2026-03-28)
- [x] **Docker host backup to NAS** — Nightly rsync (2 AM) + weekly disk image (Sunday 3 AM) to NAS:/volume1/HomelabBackup/nvr/. NFS mounted at /mnt/HomelabBackup via fstab. Restore guide at RESTORE.md on NAS. Script: /home/ryan/backup.sh. Keeps 2 most recent images. (2026-03-28)
- [x] **Fix CrowdSec Suricata parsing** — Acquisition label was `suricata` but parser expected `suricata-evelogs`. Fixed in /usr/local/etc/crowdsec/acquis.d/suricata.yaml. (2026-03-28)
- [x] **Clean up orphaned ACME config** — Removed orphaned AcmeClient cron job and config remnants from OPNsense config.xml. Plugin was already uninstalled. (2026-03-28)

## Completed
- [x] **Fix CrowdSec crash** — Bad YAML in caddy.yaml + wrong log paths in acquis.yaml (fixed 2026-03-28)
- [x] **CrowdSec escalating bans** — 24h base, escalating for repeat offenders (configured 2026-03-28)
- [x] **CrowdSec http-dos collection** — Installed 2026-03-28
- [x] **Remove Docker auto-update cron** — Removed 2026-03-27, Ryan updates manually now
