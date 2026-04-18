# ccr -- Repo Guidelines

Remote session manager for Claude Code. Single bash script (`ccr`) with config file (`~/.ccr`).

## Repo conventions

- Single script architecture -- all logic in `ccr`, no external dependencies beyond standard tools
- `~/.ccr` is the only config file, tab-separated `key=value`
- `~/.ccr-tags` is the tag registry on the hub, tab-separated (tag, vm, directory, mode)
- `~/.ccr-run/` contains auto-generated launcher scripts (not versioned)
- Hub machine runs `role=relay`, remote machines run `role=remote`
- VM inventory is read from YAML via `yq` on the hub

## Key design decisions

- **Direct IP connections** from hub to VMs (not through tunnel relay) for reliability
- **Launcher scripts** written to `~/.ccr-run/<tag>.sh` to avoid nested quoting issues with tmux/SSH
- **Retry loop** in launcher scripts keeps windows alive on failure
- **`unset TMUX`** in launchers to allow nested tmux sessions
- **Per-VM overrides** in `vm-inventory.yaml` for user, port, auth method

## Testing changes

1. Edit `~/bin/ccr` locally
2. `bash -n ~/bin/ccr` to validate syntax
3. `scp ~/bin/ccr user@hub:~/bin/ccr` to deploy
4. `ccr hub` to test

## File structure

```
ccr                  # Main script (deploy to ~/bin/ccr)
ccr-hub-setup.sh     # One-time setup helper
README.md            # User documentation
CLAUDE.md            # This file
CHANGELOG.md         # Version history
```
