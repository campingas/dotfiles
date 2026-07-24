# Fleet Sync

Dotfiles can be copied across the local fleet, but remote changes must be explicit and confirmed.

The local hardware inventory repo is the source of truth for machines, hostnames, SSH aliases, operating systems, and access notes. Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention before deciding where a dotfile should go.

## Desired Flow

Select the source files from `dots/`.

Resolve target hosts from the hardware inventory or from explicit user instructions.

Show a dry-run summary with host, source file, destination path, and command shape.

Wait for explicit confirmation.

Copy only the approved files to only the approved hosts.

Report what changed and which hosts were skipped or failed.

## Safety Rules

Never copy files to a remote machine without confirmation.

Never invent host details when the hardware repo has an inventory entry.

Never overwrite an unrelated remote file without making the destination clear first.

Keep Bash files suitable for agents and compatibility sessions.

Keep zsh suitable for human SSH sessions without automatic multiplexer startup.

Treat remote Herdr use as an explicit per-host choice; never infer installation, startup, or config deployment from the local workflow.

## Helper

`scripts/fleet-sync.sh` automates the confirmed copy step without owning fleet inventory.

Pass one or more existing SSH aliases with `--host` and one or more file paths relative to `dots/` with `--file`. The helper maps each file to the same path below the remote home.

The default is a network-free preview that shows every host, source, destination, SSH directory command, and SCP command. `--apply` is the explicit confirmation boundary and executes only the displayed combinations.

Host facts remain in the local hardware inventory repo. The helper validates explicit aliases and source paths but does not discover or store machines.

Example preview:

```sh
scripts/fleet-sync.sh --host example-host --file .zshrc --file .config/herdr/config.toml
```
