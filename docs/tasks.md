# Tasks

This file tracks current dotfiles work so the user and agents can see what changed and what remains open.

## Current Focus

Keep this repo as the single source for shell dotfiles plus coding-agent configuration.

Keep default context small: `AGENTS.md` routes to focused docs instead of carrying full operational detail.

Keep fleet updates confirmation-gated. Agents may prepare a deployment plan, but they must wait for confirmation before copying files to remote machines.

## Open Items

Run `scripts/agents-syncs.sh` after changing `dots/.claude/CLAUDE.md`, `dots/.codex/AGENTS.md`, `dots/.claude/skills/`, or `dots/.codex/skills/`.

Design a fleet-sync helper only after the local dotfile and agent-config sync workflow has settled.

## Recent Notes

The former standalone skills repo content now lives under `dots/.claude/` and `dots/.codex/`.

`docs/agent-config.md` defines the local agent-config sync workflow.

`docs/bash.md` defines Bash fast-path behavior and validation.

`repo-agents-md` now captures the workflow for concise repo-specific agent contracts.

## Validation

For docs-only changes, inspect the Markdown and run a search for stale placeholders, private absolute paths, and old layout names.

For Bash changes, run `bash -n dots/.bashrc dots/.profile` and `shellcheck dots/.bashrc dots/.profile`.

For zsh or tmux changes, validate the affected startup file and make sure the SSH tmux escape hatch remains documented.

For agent-config changes, run `bash -n scripts/agents-syncs.sh` and `shellcheck scripts/agents-syncs.sh`.
