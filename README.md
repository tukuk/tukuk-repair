# Tukuk Server Repair & Self-Healing Agent (`tukuk-repair`)

An intelligent, automated diagnostic and self-healing agent for Tukuk-OS servers. It continuously monitors backend health, manages PM2 processes, handles log hygiene, enforces correct file permissions, and automatically restores service stability without requiring manual intervention.

## Features

- **Process & PM2 Management**: Recovers unresponsive Node processes, manages cluster/fork memory limits, and ensures zero downtime.
- **Dependency & Port Check**: Verifies port 3000 availability (pure Node, Nginx-free architecture), Meilisearch status, and Cloudflare tunnel connection.
- **Filesystem & Permission Hygiene**: Automatically corrects ownership on `/opt/tukuk-os/` data and logs (`tukuk:tukuk`).
- **Log & Temp Rotation**: Purges stale log files and temporary build artifacts to maintain optimal disk space.

## Usage

```bash
sudo bash repair.sh
```

## License

MIT License
