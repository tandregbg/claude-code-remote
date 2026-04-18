# Changelog

All notable changes to ccr.

---

## v0.9.3 -- 2026-04-18

### Added
- **Direct VM connections** -- hub connects directly to VM IPs instead of going through tunnel relay
- **Mode option for local tags** -- `-m shell` or `-m claude` (default)
- **Retry loop** -- hub windows stay alive on failure, retry every 10 seconds
- **Per-VM inventory overrides** -- custom user, port, auth per VM in `vm-inventory.yaml`

### Changed
- Tags now have a 4th column: mode (`claude` or `shell`)
- `ccr hub list` shows mode column

### Fixed
- `~` path expansion from remote machines now handled correctly
- Paths with spaces (e.g. iCloud directories) properly quoted in launcher scripts
- `local` keyword used outside function context in remote delegation

---

## v0.9.2 -- 2026-04-16

### Added
- **Local hub sessions** -- `ccr hub add local` for shell/claude sessions on the hub machine itself
- Directory discovery for local projects (`~/Projects`, `~/repos`, `~/workspace`)

---

## v0.9.1 -- 2026-04-16

### Added
- **Tag registry** (`~/.ccr-tags`) -- named bookmarks mapping to VM + directory
- **`ccr hub add <vm>`** -- interactive setup with directory discovery
- **`ccr hub <tag>`** -- open saved tags directly
- **Auto-restore** -- recreates all tagged windows on hub start
- **Color-coded status bar** -- unique color per hub window
- **Tailscale fallback** -- `relay_host_fallback` in `~/.ccr`

### Fixed
- Non-interactive SSH PATH issues (`tmux`, `sshpass` not found)
- Hub windows now focus newly added window

---

## v0.9.0 -- 2026-04-16

### Added
- **ccr hub** -- tmux session hub for resilient multi-session management
- Hub subcommands: `hub`, `hub <tag>`, `hub add`, `hub list`, `hub refresh`, `hub remove`
- Remote delegation: laptop commands transparently SSH to hub
- **ccr-hub-setup.sh** -- one-time setup script

### Changed
- VM tmux prefix changed to `Ctrl+a` (avoids conflict with hub `Ctrl+b`)

---

## v0.8.0 -- 2026-04-01

### Added
- Tailscale hosts in tunnel relay (5 peers, ports 45001-45005)

---

## v0.7.0 -- 2026-04-01

### Added
- Initial release
- **ccr** -- Claude Code Remote launcher with role-based config
- tmux session wrapping for persistent Claude Code sessions
- SSH tunnel relay integration
- `ccr <vm>`, `ccr <vm> -c`, `ccr <vm> -n <name>`
