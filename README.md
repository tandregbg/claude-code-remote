# ccr -- Claude Code Remote

Remote session manager for Claude Code across multiple machines. Manages SSH connections to VMs, persistent tmux sessions, and a hub system for resilient multi-session workflows.

## What it does

- **Single VM sessions:** SSH to a VM, wrap Claude Code in tmux so it survives disconnects
- **Hub mode:** Manage all sessions from one tmux session on a central hub machine. One reconnect restores everything.
- **Tag system:** Bookmark VM + directory combinations with meaningful names. Auto-restores on reboot.
- **Local sessions:** Run Claude Code on the hub machine itself, not just remote VMs
- **Tailscale fallback:** Automatic failover when primary network is unavailable

## Architecture

```
Laptop (role=remote)
  |
  ssh to hub (with Tailscale fallback)
  |
Hub machine (role=relay)
  |
  tmux session "ccr-hub"
  ├── window "project-a"     → ssh <vm-ip>:<port>    → claude in tmux
  ├── window "project-b"     → ssh <vm-ip>:<port>    → claude in tmux
  ├── window "ops"           → local shell            → claude
  └── ...
```

### Roles

| Role | Where | What it does |
|------|-------|-------------|
| `relay` | Hub machine | Connects directly to VMs, manages tmux hub, stores tags |
| `remote` | Laptop/other | Delegates all hub commands to the relay via SSH |

### Connection layers

When on the hub machine, ccr connects **directly** to VM IPs. No tunnel relay needed.

When on a remote machine, ccr SSHes to the hub and runs commands there via ProxyJump.

## Installation

### Hub machine

```bash
# 1. Place the script
mkdir -p ~/bin
cp ccr ~/bin/ccr
chmod +x ~/bin/ccr

# 2. Create config
cat > ~/.ccr << 'EOF'
role=relay
vm_user=<default-ssh-user>
vm_password=<default-ssh-password>
vm_dir=~/src
vm_port_base=44000
vm_ssh_port=5544
claude_flags=--dangerously-skip-permissions
EOF

# 3. Dependencies
brew install tmux yq sshpass
```

### Laptop / remote machine

```bash
# 1. Copy ccr from hub (or clone this repo)
scp user@hub-machine:~/bin/ccr ~/bin/ccr
chmod +x ~/bin/ccr

# 2. Create config
cat > ~/.ccr << 'EOF'
role=remote
relay_host=user@hub-machine
relay_host_fallback=user@<tailscale-ip>   # optional
vm_user=<default-ssh-user>
vm_password=<default-ssh-password>
vm_dir=~/src
vm_port_base=44000
vm_ssh_port=5544
claude_flags=--dangerously-skip-permissions
EOF

# 3. Dependencies
brew install sshpass
```

### VM inventory

The hub reads VM IPs from a YAML inventory file. Configure the path in the script or use the default location.

Format:

```yaml
defaults:
  user: <ssh-user>
  auth: password
  password: <ssh-password>
  port: 5544

vms:
  my-dev-vm:
    ip: 10.0.1.100
  my-web-vm:
    ip: 10.0.1.101
  special-vm:
    ip: 10.0.1.200
    user: admin
    port: 22
    auth: key
```

Per-VM overrides for `user`, `port`, and `auth` (key/password) are supported.

## Usage

### Basic (single session)

```bash
ccr                           # List VMs and active sessions
ccr <vm>                      # Start Claude Code on a VM
ccr <vm> -c                   # Reattach to existing session
ccr <vm> -n "my-task"         # Named session
```

### Hub mode

```bash
ccr hub                       # Attach to hub (auto-restores saved tags)
ccr hub <tag>                 # Open a saved tag
ccr hub list                  # Show windows and registered tags
ccr hub refresh               # Reconnect dead windows
```

### Adding sessions to the hub

```bash
# Interactive (discovers directories on VM)
ccr hub add <vm>

# Explicit
ccr hub add <vm> -t my-tag -d ~/src/project

# Local hub machine session
ccr hub add local -t ops -d ~/workspace
ccr hub add local -t shell-only -d ~/workspace -m shell

# Remove a tag
ccr hub remove <tag>
```

### Tag system

Tags are saved in `~/.ccr-tags` on the hub machine:

```
# tag          vm          directory              mode
project-a      my-dev-vm   ~/src/project-a        claude
ops            local       ~/workspace            shell
goals          local       ~/documents/goals      claude
```

- **mode `claude`** (default): starts Claude Code with configured flags
- **mode `shell`**: opens a plain shell

Tags persist across reboots. When `ccr hub` creates a new hub session, it auto-restores all saved tags.

## Hub navigation

| Keys | Action |
|------|--------|
| `Ctrl+b, w` | List all windows (color-coded) |
| `Ctrl+b, <number>` | Switch to window N |
| `Ctrl+b, n` / `Ctrl+b, p` | Next / previous window |
| `Ctrl+b, d` | Detach from hub (all sessions keep running) |
| `Ctrl+b, .` | Renumber current window |
| `Ctrl+b, :` | tmux command prompt |
| `Ctrl+a, ...` | Inner VM tmux commands (nested sessions) |

### Rearranging windows

```
Ctrl+b, :    then    swap-window -t 0          # move current to position 0
Ctrl+b, :    then    swap-window -s 3 -t 1     # swap window 3 and 1
Ctrl+b, .                                      # renumber current window
```

### Mouse support

Mouse scrolling is auto-enabled on both hub and inner VM tmux sessions. If it stops working after a reconnect:

```
# Hub level:
Ctrl+b, :    then    set -g mouse on

# VM level:
Ctrl+a, :    then    set -g mouse on
```

## After a disconnect

```bash
# Just reconnect -- all windows are restored
ccr hub
```

If the hub session was lost (e.g. hub machine reboot), `ccr hub` auto-restores all saved tags.

If individual windows died:

```bash
ccr hub refresh
```

Windows have a retry loop -- they show the error and reconnect automatically every 10 seconds.

## Tailscale fallback

When `relay_host_fallback` is set in `~/.ccr`, the script automatically tries the fallback if the primary host is unreachable:

```
(primary unreachable, using Tailscale: user@<fallback-ip>)
```

No manual intervention needed.

## Multiple hubs

Each machine with `role=relay` is an independent hub with its own `~/.ccr-tags` and `~/.ccr-run/`. Deploy `ccr` + `~/.ccr` on any machine to create a new hub.

From a laptop, switch between hubs by specifying the host:

```bash
# Default hub
ccr hub

# Different hub
ssh user@other-hub "ccr hub"
```

## Files

| File | Location | Purpose |
|------|----------|---------|
| `ccr` | `~/bin/ccr` (both machines) | Main script |
| `~/.ccr` | Both machines | Role and connection config |
| `~/.ccr-tags` | Hub machine | Tag registry (persisted) |
| `~/.ccr-run/` | Hub machine | Auto-generated launcher scripts |
| `vm-inventory.yaml` | Hub machine | VM IP/port/auth source of truth |
| `ccr-hub-setup.sh` | Laptop | One-time hub setup helper |

## Configuration reference

### ~/.ccr options

| Key | Default | Description |
|-----|---------|-------------|
| `role` | `relay` | `relay` (hub) or `remote` (laptop) |
| `relay_host` | | SSH target for remote role (e.g. `user@host`) |
| `relay_host_fallback` | | Tailscale fallback SSH target |
| `vm_user` | | Default VM SSH user |
| `vm_password` | | Default VM SSH password |
| `vm_dir` | `~/src` | Default working directory on VMs |
| `vm_port_base` | `44000` | Base port for tunnel mapping |
| `vm_ssh_port` | `5544` | Default VM SSH port |
| `claude_flags` | `--dangerously-skip-permissions` | Flags passed to Claude Code |
