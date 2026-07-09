# AGENTS.md

This repo manages personal shell and terminal configuration across local and SSH machines.

## Repository Layout

`dots/` contains the files intended to be deployed into home directories.

`docs/` contains setup notes, fleet-sync guidance, and current task state.

`README.md` is the short human entrypoint. Keep it general and route details into `docs/`.

## Shell Roles

Bash is the agent and compatibility shell. Keep `.bashrc`, `.profile`, and `.inputrc` simple, portable, quiet in non-interactive sessions, and written as pure Bash or POSIX shell where appropriate.

Interactive agent Bash should stop after core environment, tool PATHs, and CDPATH setup. `DOTFILES_AGENT_SHELL=1` forces that fast path, while `DOTFILES_AGENT_SHELL=0` forces the full interactive setup.

Zsh is the human interface shell. Keep `.zshrc` concise, efficient, and optimized for interactive SSH use with tmux.

The normal user workflow is Ghostty with cmux on the main laptop, then SSH into other computers where zsh should auto-attach to tmux when configured.

When shell choice matters for an agent task, prefer Bash unless the user explicitly asks about zsh.

## Working Rules

Read directly related files before editing. For shell changes, inspect the startup chain and adjacent docs before patching.

Keep changes small and direct. If a simpler approach solves the problem, propose it or use it.

Do not revert user changes unless explicitly requested.

Do not commit unless explicitly asked. If a commit is requested, use a conventional commit message.

Never push unless the user explicitly asks.

Do not add assistant names, co-authorship metadata, or agent branding unless explicitly requested.

## Fleet Updates

Dotfile deployment across the network must be confirmation-gated.

Before copying files to another machine, show the target hosts, source files, destination paths, and commands that will run.

Wait for explicit user confirmation before changing remote machines.

Use the local hardware inventory repo as the durable source of truth for host inventory and access notes. Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention.

## Documentation

Use single-line paragraphs in Markdown.

Update routed docs when behavior, architecture, setup, or workflow changes.

Use `docs/tasks.md` for transparent current work and `docs/fleet-sync.md` for fleet deployment expectations.
