# Changelog

All notable changes to ccr.

---

## v0.10.0 -- 2026-05-08

### Added
- **WireGuard host support** -- inventory lookup now checks `vms:`, `tailscale:`, and `wireguard:` sections
- **Per-tag colors** -- `ccr hub add <vm> -t tag -c cyan` sets a persistent color for the tag in the status bar. Available colors: green, yellow, blue, magenta, cyan, red, white. Tags without a color auto-cycle through the palette.
- **`--host` override in all hub subcommands** -- `ccr hub list --host user@ip` works for add, refresh, remove, etc.

### Changed
- **SSH config prefix** -- now matches both `relay-` (new convention) and `relay_` (legacy) when looking up ports and users
- Non-VM hosts (tailscale + wireguard) default to port 22 and key auth (previously only tailscale did)

### Fixed
- **Remote VM path expansion** -- `~` in `-d` flag for remote VMs no longer expands to the hub machine's `$HOME`. Paths are stored correctly for the target VM.
- **`doable-server` tag** updated to reference `doable-proxy` (WireGuard peer) after VM decommission

---

## v0.9.7 -- 2026-04-21

### Added
- **Auto mouse support** -- mouse scrolling enabled on both hub and inner VM tmux sessions on every connect/attach
- Window management documented (swap, renumber, rearrange)

---

## v0.9.6 -- 2026-04-20

### Added
- **Tailscale host support** -- hub now resolves VMs from both `vms:` and `tailscale:` sections in inventory
- Tailscale hosts default to port 22 and key auth

### Fixed
- `~` path in `-d` flag for remote VMs was expanding on the hub machine instead of the target VM

---

## v0.9.5 -- 2026-04-19

### Added
- **Multi-hub support** -- `--host user@ip` flag to connect to any hub from any machine
- **`ccr-setup`** -- LXC container discovery script. Scans `lxc list`, generates `vm-inventory.yaml`
  - `ccr-setup` -- discover and generate inventory
  - `ccr-setup --check` -- also test SSH connectivity and claude installation per VM
  - `ccr-setup --dry-run` -- preview without writing
- **Linux compatibility** -- portable `sed -i` wrapper (`_sed_i`) for macOS and Linux
- **VM inventory lookup** -- `hub add` now checks `vm-inventory.yaml` directly, not just tunnel ports

### Fixed
- `_sed_i` recursive call bug (infinite recursion on macOS)
- `~` in config values (e.g. `vm_inventory=~/path`) now expands correctly
- VM verification in `hub add` works on machines without tunnel-relay.sh

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
