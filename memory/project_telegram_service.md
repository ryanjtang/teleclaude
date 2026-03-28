---
name: Telegram service setup
description: Claude Code runs as a systemd user service with Telegram channel, using expect to auto-accept the bypass permissions prompt
type: project
---

Claude Code runs as a headless Telegram bot via systemd user service `claude-telegram.service`.

Key details:
- Service file: `~/.config/systemd/user/claude-telegram.service`
- Start script: `~/start-claude.sh` (expect script that auto-accepts bypass permissions prompt)
- Uses `--permission-mode auto` caused "auto mode temporarily unavailable" errors; `--dangerously-skip-permissions` with expect to navigate TUI menu works
- `hasTrustDialogAccepted: true` must be set in `.claude.json` for `/home/ryan` project
- Linger enabled for user ryan so service starts on boot
- Telegram bot token in `~/.claude/channels/telegram/.env`
- Allowed Telegram user ID: 1041824812

**Why:** User wants Claude accessible via Telegram 24/7, surviving reboots.
**How to apply:** If service breaks, check journalctl logs and ensure the expect script handles any new interactive prompts.
