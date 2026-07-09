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

Keep zsh and tmux files suitable for human SSH sessions.

## Future Helper

A future helper can automate the confirmed copy step, but it should stay small.

It should read selected files from `dots/`, use existing SSH aliases, show an exact dry run by default, and require a confirmation flag or prompt before writing remote files.

It should not own the fleet inventory. Host facts belong in the local hardware inventory repo.
