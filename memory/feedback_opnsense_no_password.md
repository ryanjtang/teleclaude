---
name: Never change OPNsense credentials
description: Do not modify OPNsense root user account, password, or SSH keys via API or console
type: feedback
---

NEVER modify the OPNsense root user account via the API or any other method. A previous Claude session changed the root password on March 24, 2026 while making API calls to /api/auth/user/set/, which locked Ryan out of the console. He had to do multiple single-user mode reboots to reset it.

**Why:** Changing the password locks Ryan out of console access, which is extremely tedious to recover from (requires physical access, single-user boot, manual password reset). It also caused a security scare — Ryan initially thought someone had compromised his network.

**How to apply:** When working with OPNsense, never call the user management API endpoints. If SSH key or user config changes are needed, tell Ryan to do it himself through the web UI. Read-only operations (logs, status, config inspection) via SSH are fine.
