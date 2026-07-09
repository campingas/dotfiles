# Current State

Last updated: 2026-07-09

## Status

This repo now owns both shell dotfiles and coding-agent configuration.

Managed home-directory files live under `dots/`.

Claude global config lives at `dots/.claude/CLAUDE.md`.

Codex global config lives at `dots/.codex/AGENTS.md`.

Claude skills live under `dots/.claude/skills/` and are linked into `~/.claude/skills/` by `scripts/agents-syncs.sh`.

Codex skills live under `dots/.codex/skills/` and are linked into `~/.codex/skills/` by `scripts/agents-syncs.sh`.

The repo-authored Claude skills are `codex-review`, `codex-implementation`, `codex-computer-use`, and `html-planning`.

The repo-authored Codex skill is `repo-agents-md`.

## Durable Decisions

`AGENTS.md` stays short and routes to focused docs.

Repo-local `AGENTS.md` files should avoid duplicating global defaults.

`docs/bash.md` owns Bash fast-path details and validation.

`docs/agent-config.md` owns Claude, Codex, and skill sync behavior.

`docs/fleet-sync.md` owns remote-machine deployment expectations.

The local hardware inventory repo remains the source of truth for machine details; this public repo should not duplicate LAN details, host inventory, or private operational notes.

## Known Issues

None currently known.

## Recommended Next Steps

See `docs/tasks.md`.
