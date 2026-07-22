# dotfiles

Personal dotfiles for the machines I use directly and over SSH.

The main laptop workflow is Ghostty with cmux locally, then SSH into other computers as needed. Human interactive shells should land in zsh, and SSH sessions should use tmux so work survives disconnects.

The Bash files are kept simple and quiet for agents, recovery sessions, and compatibility. When a task asks an agent to inspect or change shell behavior, prefer Bash unless the request explicitly targets zsh.

Agent Bash has a fast path for lower startup latency. Details and benchmark numbers live in `docs/bash.md`.

Managed files live in `dots/`. Setup and operational notes live in `docs/`.

Agent configuration is managed here too: `dots/.claude/CLAUDE.md`, native Codex orchestration policy in `dots/.codex/AGENTS.md`, skills under the runtime-specific `skills/` directories, and executable Codex role definitions under `dots/.codex/agents/`. The Codex app owns global runtime settings such as multi-agent enablement and concurrency.

Fleet updates are confirmation-gated. An agent may prepare the list of files and target machines, but it must show the plan and wait for confirmation before copying dotfiles across the network.

`scripts/fleet-sync.sh` provides that dry-run-first boundary for explicitly selected hosts and files; it performs remote writes only with `--apply`.

## Prompt

Install [Starship](https://starship.rs/) where the zsh prompt should use it.

The managed zsh setup initializes Starship when it is available, so machines without Starship still get a usable shell.

## Skills

| Skill | Runtime | Purpose |
|-------|---------|---------|
| `html-planning` | Claude, Codex, compatible agents | Render and archive versioned HTML plans and reports with agent attribution |
| `repo-agents-md` | Codex | Create or update concise repo-specific AGENTS.md files |

## Installation

Run `scripts/agents-syncs.sh` after editing config files or adding a skill.

It copies `dots/.claude/CLAUDE.md` to `~/.claude/CLAUDE.md`, copies `dots/.codex/AGENTS.md` to `~/.codex/AGENTS.md`, symlinks skills and Codex role profiles into their live directories, and prunes stale symlinks that point back into this repo. It does not replace app-managed global configuration files.

The repo is the source of truth for the files it manages: live copies are overwritten (the replaced diff is printed), and the script is idempotent.

Skills that exist in live skill directories but were not authored in this repo are out of scope; the script leaves them untouched.

## Working in this repo

Read `AGENTS.md` for the repo-wide rules, then `docs/tasks.md` and `docs/current-state.md` for what is active and where things stand.

Once `scripts/agents-syncs.sh` has linked a skill, edits under `dots/.claude/skills/` or `dots/.codex/skills/` are seen through the symlink; no per-skill install step is needed.
