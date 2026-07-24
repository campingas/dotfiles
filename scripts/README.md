# Sync Scripts

Use the two sync scripts for separate configuration domains.

## Agent configuration

Run `agents-syncs.sh` only for `.claude` and `.codex` configuration:

```sh
scripts/agents-syncs.sh
```

It copies the managed global instruction files, removes the retired repo-managed dispatch file when its contents are unchanged, then links repo-authored skills and Codex agent profiles. It does not deploy shell, editor, or application configuration.

## User dotfiles

Run `dots-syncs.sh` to link the user-facing dotfiles into the current user's home directory:

```sh
scripts/dots-syncs.sh
```

The default is a read-only preview. It covers:

- Bash and Readline: `.bashrc`, `.profile`, and `.inputrc`
- Zsh: `.zshrc`
- Vim: `.vimrc`
- Application configuration: each file below `dots/.config/`, including Ghostty, Herdr, and Starship, linked to the same relative path below `~/.config/`

The script links individual files under `~/.config`; it does not replace the directory or unrelated application files. Existing destinations are preserved in a timestamped directory below `~/.local/state/dotfiles-backups/` when changes are applied.

The preview also identifies retired `~/.tmux.conf` and `~/.config/cmux/cmux.json` symlinks only when they point exactly to the former paths in this checkout. Apply removes those exact links and leaves regular files, links to other targets, and unrelated files untouched.

After reviewing the preview, apply it explicitly:

```sh
scripts/dots-syncs.sh --apply
```

`dots-syncs.sh` does not manage `.claude`, `.codex`, or remote fleet deployment.

## Fleet copy

Run `fleet-sync.sh` with explicit hosts and files to preview remote copies:

```sh
scripts/fleet-sync.sh --host example-host --file .zshrc --file .config/herdr/config.toml
```

The helper accepts files relative to `dots/`, maps each file to the same path below the remote home, prints every host, source, destination, and command, and performs no network operation by default. Remote Herdr deployment is explicit; after reviewing the full preview, pass `--apply` to execute only those displayed SSH and SCP commands.

Run the isolated sync regression checks with:

```sh
scripts/tests/sync-scripts.sh
```
