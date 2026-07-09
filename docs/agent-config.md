# Agent Config

This repo tracks the user's global coding-agent configuration under `dots/`.

## Layout

`dots/.claude/CLAUDE.md` is the source for `~/.claude/CLAUDE.md`.

`dots/.claude/skills/` contains repo-authored Claude skills.

`dots/.codex/AGENTS.md` is the source for `~/.codex/AGENTS.md`.

`dots/.codex/skills/` contains repo-authored Codex skills.

Root `AGENTS.md` is the repo-local routing contract for agents working in this checkout, and should not duplicate global defaults.

Root `CLAUDE.md` is a thin adapter that points Claude at root `AGENTS.md`.

## Sync

Run `scripts/agents-syncs.sh` after editing Claude config, Codex config, or repo-authored skills.

The script copies global adapter files into `~/.claude/` and `~/.codex/`.

The script symlinks each directory under `dots/.claude/skills/` into `~/.claude/skills/`.

The script symlinks each directory under `dots/.codex/skills/` into `~/.codex/skills/`.

The script prunes only stale skill symlinks that point back into this repo.

Skills that already exist in live skill directories but do not point into this repo are left untouched.

## Public Repo Safety

Do not duplicate machine inventory, LAN details, serials, or private operational notes here.

Refer to the local hardware inventory repo generically when hardware context is needed.

Keep global agent instructions concise and public-safe.

Use the Codex `repo-agents-md` skill when creating or refreshing repo-local `AGENTS.md` files.
