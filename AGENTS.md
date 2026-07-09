# AGENTS.md

This repo manages shell dotfiles and global coding-agent configuration.

Global agent preferences live under `dots/.claude/CLAUDE.md` and `dots/.codex/AGENTS.md`; do not duplicate them here unless this repo needs a stricter local rule.

## Read First

Use `README.md` for the human overview.

For Bash work, read `docs/bash.md` before editing `.bashrc`, `.profile`, or `.inputrc`.

For Claude, Codex, or skill sync work, read `docs/agent-config.md`.

For fleet deployment, read `docs/fleet-sync.md` and wait for explicit confirmation before copying files to another machine.

Use `docs/tasks.md` and `docs/current-state.md` for current work state.

## Repo Rules

Bash is the agent and compatibility shell.

Zsh is the human interactive shell.

The normal user workflow is Ghostty with cmux locally, then SSH to hosts where zsh may auto-attach to tmux.

When shell choice matters for an agent task, prefer Bash unless the user explicitly asks about zsh.

Run `scripts/agents-syncs.sh` only when syncing local live agent config is intended.

Do not duplicate machine inventory, LAN details, serials, or private operational notes in this public repo.

## Validation

For docs-only changes, scan changed docs for stale placeholders, private paths, and old layout names.

For Bash changes, run `bash -n dots/.bashrc dots/.profile` and `shellcheck dots/.bashrc dots/.profile`.

For agent-config changes, run `bash -n scripts/agents-syncs.sh` and `shellcheck scripts/agents-syncs.sh`.
