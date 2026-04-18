#!/bin/bash
# ccr-hub-setup.sh - One-time setup for ccr hub on the relay machine + VMs
# Run from the remote machine (laptop) when the relay is reachable.
#
# What it does:
# 1. Copies updated ccr to the relay machine
# 2. Configures relay tmux for hub-friendly status bar
# 3. Sets Ctrl+a as prefix on VMs (avoids nested tmux conflict)
#
# Prerequisites: ~/.ccr must exist with relay_host set

set -euo pipefail

CONFIG="$HOME/.ccr"

# Load config
RELAY_HOST=""
VM_PASSWORD=""

if [ -f "$CONFIG" ]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        case "$key" in
            relay_host)  RELAY_HOST="$value" ;;
            vm_password) VM_PASSWORD="$value" ;;
        esac
    done < "$CONFIG"
fi

if [ -z "$RELAY_HOST" ]; then
    echo "Error: relay_host not set in ~/.ccr"
    exit 1
fi

RELAY_SCRIPT="workspace/scripts/tunnel-relay.sh"

echo "=== ccr hub setup ==="
echo "Relay: $RELAY_HOST"
echo ""

# 1. Copy ccr to relay
echo "[1/3] Copying ccr to relay..."
scp ~/bin/ccr "${RELAY_HOST}:~/bin/ccr"
ssh "$RELAY_HOST" "chmod +x ~/bin/ccr"
echo "  Done."

# 2. Configure relay tmux
echo "[2/3] Configuring relay tmux..."
ssh "$RELAY_HOST" 'grep -q "ccr hub config" ~/.tmux.conf 2>/dev/null || cat >> ~/.tmux.conf << '\''HUBCONF'\''

# --- ccr hub config ---
set -g status-left "[hub] "
set -g status-right "%H:%M"
set -g window-status-format " #I:#W "
set -g window-status-current-format " #I:#W "
set -g window-status-current-style "bg=green,fg=black"
set -g mouse on
HUBCONF'
echo "  Done."

# 3. Set Ctrl+a prefix on VMs
echo "[3/3] Setting Ctrl+a prefix on VMs..."
vm_ports=$(ssh -o ConnectTimeout=5 "$RELAY_HOST" "$RELAY_SCRIPT list-ports" 2>/dev/null || true)

if [ -z "$vm_ports" ]; then
    echo "  Could not get VM port list from relay."
    echo "  You can manually set the prefix on each VM:"
    echo "    echo -e 'set-option -g prefix C-a\nunbind C-b\nbind C-a send-prefix' >> ~/.tmux.conf"
else
    echo "$vm_ports" | while read -r port; do
        if [ -n "$VM_PASSWORD" ]; then
            ssh "$RELAY_HOST" "sshpass -p '$VM_PASSWORD' ssh -o StrictHostKeyChecking=no -p $port ubuntu@localhost 'grep -q \"prefix C-a\" ~/.tmux.conf 2>/dev/null || echo -e \"set-option -g prefix C-a\nunbind C-b\nbind C-a send-prefix\" >> ~/.tmux.conf'" 2>/dev/null && echo "  Port $port: OK" || echo "  Port $port: SKIP (unreachable)"
        fi
    done
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Quick reference:"
echo "  ccr hub                  -- attach to hub (one reconnect for all sessions)"
echo "  ccr hub add <vm>         -- add VM window interactively"
echo "  ccr hub add local -t ops -- add local shell/claude session"
echo "  ccr hub list             -- show windows and tags"
echo "  ccr hub refresh          -- reconnect dead windows"
echo ""
echo "Keybindings inside hub:"
echo "  Ctrl+b, w                -- list all VM windows"
echo "  Ctrl+b, <number>         -- switch to VM window N"
echo "  Ctrl+b, n / p            -- next / previous VM"
echo "  Ctrl+b, d                -- detach hub (all VMs keep running)"
echo "  Ctrl+a, ...              -- inner VM tmux commands"
