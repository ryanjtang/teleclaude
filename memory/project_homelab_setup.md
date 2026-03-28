---
name: Homelab infrastructure
description: Ryan's homelab setup - Docker services, networking, hardware details for home server
type: project
---

Home server: 13th Gen Intel i7-13700HX, NVIDIA RTX 4070 (8GB), running Ubuntu with Docker.

**Networking:**
- enp111s0: 192.168.0.20 (primary, has default gateway 192.168.0.1) — next to power connector
- enp108s0: 192.168.0.27 (no gateway, LAN only)
- enp108s0.10: 192.168.10.2 (camera VLAN)
- OPNsense firewall at 192.168.0.1 (web UI on port 8443, Suricata IDS/IPS, SSH as root)
- NAS at 192.168.0.24 (NFS, allows 192.168.0.20 and 192.168.0.27)
- UFW enabled on server
- VLANs: LAN (1, 192.168.0.0/24), Camera (10, 192.168.10.0/24), IoT (20, 192.168.20.0/24), Guest (30, 192.168.30.0/24), WAN (888), WireGuard (10.10.10.0/24)
- Omada controller on Docker (port 8043/8088), manages SG3218XP-M2 switch + 2x EAP670 APs
- Switch: L2 only, "LAN Trunk" profile on ports 1-14/17 (no WAN VLAN), WAN VLAN isolated to ports 15+18
- WireGuard on OPNsense: wg0, 10.10.10.1/24, UDP 51820, client 10.10.10.5 restricted to 192.168.0.20:5500 only
- DNS: Pi-hole at 192.168.0.22 + pihole2 at 192.168.0.26

**Docker services:**
- Home Assistant (host network)
- Z-Wave JS UI (ports 8091/3000, Zooz 800 stick, S2 security keys configured 2026-03-23)
- Frigate (stable-tensorrt image, RTX 4070 GPU decoding, ONNX detector with YOLOv9-c 640px model, 4 Reolink cameras: frontreo/backreo/garagereo/masterreo, Coral USB removed)
- Portainer (port 9001:9000, 9443)
- Speedtest-tracker (host networking, ports 80/443, AT&T server 68864)
- Various others: Dockge, Homepage, Uptime Kuma, Vaultwarden, Omada controller, changedetection

**Why:** Understanding the full setup helps troubleshoot Docker networking, port conflicts, and service interactions.
**How to apply:** When debugging services, check UFW rules, interface routing, and Docker network modes. IPS on OPNsense can throttle traffic.
