---
name: Docker compose cleanup recommendations
description: Pending cleanup tasks across all Docker compose files - security, correctness, and tidiness improvements
type: project
---

Reviewed all 11 compose files on 2026-03-23. No changes made yet - awaiting Ryan's approval per item.

**1. Uptime Kuma** (`~/uptimekuma/docker-compose.yml`)
- Fix TZ=PST → TZ=America/Los_Angeles (PST is not a valid tz database name)
- Remove deprecated `version: "3.8"` (Docker Compose V2 ignores it)

**2. Home Assistant** (`~/homeassistant/docker-compose.yml`)
- zwave-js-ui: remove `privileged: true` since explicit `devices:` is already mapped — more secure

**3. Frigate** (`~/frigate/docker-compose.yml`)
- Remove `/dev/bus/usb:/dev/bus/usb` device mapping (Coral USB was removed)
- Consider replacing `privileged: true` with explicit device mappings (`/dev/dri` only)
- Remove redundant `ports:` section (8971, 8554) since `network_mode: host` exposes all ports anyway

**4. Changedetection** (`~/changedetection/docker-compose.yml`)
- Remove large block of commented-out config/docs for readability
- Consider lowering MAX_CONCURRENT_CHROME_PROCESSES from 10 (overkill for homelab)

**5. Speedtest Tracker** (`~/speedtest-tracker/docker-compose.yml`)
- Remove empty optional DB env vars (DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, DB_PASSWORD) — unused with sqlite

**6. Dockge** (`~/dockge/docker-compose.yml`)
- Mounts entire /home/ryan into the container — consider scoping tighter to only directories with stacks

**7. Omada Controller** (`~/omada-controller/docker-compose.yml`)
- Uses local Docker volumes (omada-data, omada-logs) instead of NFS — config would be lost if server dies. Consider moving to NFS like other services.

**Why:** Incremental improvements to security (removing unnecessary privileged mode), correctness (timezone), and maintainability. None are urgent or breaking.
**How to apply:** Address individually with Ryan's confirmation before making each change. Some changes (removing privileged, changing volumes) require container recreation.