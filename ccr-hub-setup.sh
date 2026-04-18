#!/bin/bash
# ccr-hub-setup.sh - One-time setup for ccr hub on Mac Studio + VMs
# Run from MacBook when Mac Studio is reachable.
#
# What it does:
# 1. Copies updated ccr to Mac Studio
# 2. Configures Mac Studio tmux for hub-friendly status bar
# 3. Sets Ctrl+a as prefix on all Proxmox VMs (avoids nested tmux conflict)

set -euo pipefail

RELAY_HOST="tomas@tomas-mac-studio"
RELAY_SCRIPT="workspace/scripts/tunnel-relay.sh"

echo "=== ccr hub setup ==="
echo ""

# 1. Copy ccr to Mac Studio
echo "[1/3] Copying ccr to Mac Studio..."
scp ~/bin/ccr "${RELAY_HOST}:~/bin/ccr"
ssh "$RELAY_HOST" "chmod +x ~/bin/ccr"
echo "  Done."

# 2. Configure Mac Studio tmux
echo "[2/3] Configuring Mac Studio tmux..."
ssh "$RELAY_HOST" 'cat >> ~/.tmux.conf << '\''HUBCONF'\''

# --- ccr hub config ---
set -g status-left "[hub] "
set -g status-right "%H:%M"
set -g window-status-format " #I:#W "
set -g window-status-current-format " #I:#W "
set -g window-status-current-style "bg=green,fg=black"
set -g mouse on
HUBCONF'
echo "  Done."

# 3. Set Ctrl+a prefix on all Proxmox VMs
echo "[3/3] Setting Ctrl+a prefix on VMs..."
vm_ports=$(ssh -o ConnectTimeout=5 "$RELAY_HOST" "$RELAY_SCRIPT list-ports" 2>/dev/null || true)

if [ -z "$vm_ports" ]; then
    echo "  Could not get VM port list from tunnel-relay.sh."
    echo "  You can manually set the prefix on each VM by running:"
    echo '    echo -e "set-option -g prefix C-a\nunbind C-b\nbind C-a send-prefix" >> ~/.tmux.conf'
    echo ""
    echo "  Or run this on Mac Studio to push to all VMs:"
    echo "  for port in \$(tunnel-relay.sh list-ports); do"
    echo "    sshpass -p ubuntu ssh -o StrictHostKeyChecking=no -p \$port ubuntu@localhost \\"
    echo "      'grep -q \"prefix C-a\" ~/.tmux.conf 2>/dev/null || echo -e \"set-option -g prefix C-a\nunbind C-b\nbind C-a send-prefix\" >> ~/.tmux.conf'"
    echo "  done"
else
    echo "$vm_ports" | while read -r port; do
        ssh "$RELAY_HOST" "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no -p $port ubuntu@localhost 'grep -q \"prefix C-a\" ~/.tmux.conf 2>/dev/null || echo -e \"set-option -g prefix C-a\nunbind C-b\nbind C-a send-prefix\" >> ~/.tmux.conf'" 2>/dev/null && echo "  Port $port: OK" || echo "  Port $port: SKIP (unreachable)"
    done
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Quick reference:"
echo "  ccr hub                  -- attach to hub (one reconnect for all sessions)"
echo "  ccr hub <vm>             -- add VM window"
echo "  ccr hub list             -- show windows"
echo "  ccr hub refresh          -- reconnect dead windows"
echo ""
echo "Keybindings inside hub:"
echo "  Ctrl+b, w                -- list all VM windows"
echo "  Ctrl+b, <number>         -- switch to VM window N"
echo "  Ctrl+b, n / p            -- next / previous VM"
echo "  Ctrl+b, d                -- detach hub (all VMs keep running)"
echo "  Ctrl+a, ...              -- inner VM tmux commands"
