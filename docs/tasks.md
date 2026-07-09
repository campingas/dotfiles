# Tasks

This file tracks current dotfiles work so the user and agents can see what changed and what remains open.

## Current Focus

Document the repo contract for a Ghostty and cmux main-laptop workflow, zsh plus tmux on SSH hosts, and Bash-first behavior for agent-facing shell work.

Keep fleet updates confirmation-gated. Agents may prepare a deployment plan, but they must wait for confirmation before copying files to remote machines.

## Open Items

Design a small fleet-sync helper only after the documentation workflow has settled.

Keep host identity, network addresses, and access notes in the local hardware inventory repo instead of duplicating them here.

## Recent Notes

`README.md` is the short human entrypoint.

`AGENTS.md` is the working contract for agents in this repo.

`docs/fleet-sync.md` defines the deploy safety boundary.

## Validation

For docs-only changes, inspect the Markdown and run a search for stale placeholders or obvious typos.

For Bash changes, validate `.bashrc`, `.profile`, and `.inputrc` before calling the work done.

For agent Bash changes, verify the fast path with `DOTFILES_AGENT_SHELL=1` and the full path with `DOTFILES_AGENT_SHELL=0`.

For zsh or tmux changes, validate the affected startup file and make sure the SSH tmux escape hatch remains documented.
