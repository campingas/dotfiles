# Sync Scripts

Use the two sync scripts for separate configuration domains.

## Agent configuration

Run `agents-syncs.sh` only for `.claude` and `.codex` configuration:

```sh
scripts/agents-syncs.sh
```

It copies the managed global instruction and dispatch files, then links repo-authored skills and Codex agent profiles. It does not deploy shell, editor, tmux, or application configuration.

## User dotfiles

Run `dots-syncs.sh` to link the user-facing dotfiles into the current user's home directory:

```sh
scripts/dots-syncs.sh
```

The default is a read-only preview. It covers:

- Bash and Readline: `.bashrc`, `.profile`, and `.inputrc`
- Zsh: `.zshrc`
- Vim: `.vimrc`
- tmux: `dots/tmux.conf` linked as `~/.tmux.conf`
- Each file below `dots/.config/`, linked to the same relative path below `~/.config/`

The script links individual files under `~/.config`; it does not replace the directory or unrelated application files. Existing destinations are preserved in a timestamped directory below `~/.local/state/dotfiles-backups/` when changes are applied.

After reviewing the preview, apply it explicitly:

```sh
scripts/dots-syncs.sh --apply
```

`dots-syncs.sh` does not manage `.claude`, `.codex`, or remote fleet deployment.
