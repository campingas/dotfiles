# Current State

Last updated: 2026-07-12

## Status

This repo now owns both shell dotfiles and coding-agent configuration.

Managed home-directory files live under `dots/`.

Claude global config lives at `dots/.claude/CLAUDE.md`.

Codex global config lives at `dots/.codex/AGENTS.md`.

Claude skills live under `dots/.claude/skills/` and are linked into `~/.claude/skills/` by `scripts/agents-syncs.sh`.

Codex skills live under `dots/.codex/skills/` and are linked into `~/.codex/skills/` by `scripts/agents-syncs.sh`.

Codex subagent profiles live under `dots/.codex/agents/` and are linked into `~/.codex/agents/` by `scripts/agents-syncs.sh`.

The repo-authored Claude skills are `codex-review`, `codex-implementation`, `codex-computer-use`, and `html-planning`.

The repo-authored Codex skills are `repo-agents-md` and `codex-dispatch`.

The repo-authored Codex agents are `lookup`, `investigate`, `implement`, `implement_fast`, `implement_deep`, `review`, and `review_fast`.

## Durable Decisions

`AGENTS.md` stays short and routes to focused docs.

Repo-local `AGENTS.md` files should avoid duplicating global defaults.

`docs/bash.md` owns Bash fast-path details and validation.

`docs/agent-config.md` owns Claude, Codex, and skill sync behavior.

Claude uses Fable medium by default and raises it to high only for explicit quality-risk triggers. Codex uses action-named profiles with Sol medium for normal implementation and risk-triggered review.

Codex keeps integration in the root session, uses at most one active delegated run when isolation helps, and controls GPT-5.6 overreach through explicit task envelopes and outcome-based stop conditions.

Codex uses an automatic exec-backed dispatcher to apply the selected profile's pinned runtime until native named-role spawning passes strict validation. Deep implementation, multiple delegated runs, and xhigh overrides remain confirmation-gated.

`docs/fleet-sync.md` owns remote-machine deployment expectations.

The local hardware inventory repo remains the source of truth for machine details; this public repo should not duplicate LAN details, host inventory, or private operational notes.

## Known Issues

Codex CLI 0.144.1 spawns untyped native children from `codex exec`, so the child inherits the root model and effort instead of a custom profile. The `codex-dispatch` skill provides a separate exec-backed compatibility path with pinned runtimes. The live `~/.codex/config.toml` remains unchanged; revalidate named roles after upgrading Codex.

The exec-backed dispatcher passes deterministic profile, confirmation, concurrency, recursion, evidence, and live-sync checks. A neutral Sol-medium smoke autonomously selected `investigate` and completed a pinned Terra-medium read-only delegated run when the root used the normal global `danger-full-access` sandbox. Read-only and workspace-write roots cannot start the nested Codex app-server process, so automatic exec-backed dispatch requires a danger-full-access root even though the selected child keeps its profile sandbox.

A proposal-only control respected the no-launch boundary but initially invented an obsolete runtime for the correct profile. After the global Codex instructions gained the fixed profile-to-runtime map, a fresh control proposed `investigate` with Terra-medium and performed no command execution or child launch.

## Pending Strong Validations

The two strict native named-role gates remain open. Run them in order using the routine in `docs/tasks.md`, and do not prompt either orchestrator to use Codex, subagents, profiles, or parallelism.

The Codex-native gate passes only when a Sol-medium root receives a naturally delegable plan or large task, chooses by itself to spawn a named profile from `dots/.codex/agents/`, and the child session records the profile name plus its configured model and effort.

The Claude-to-Codex gate passes only after the Codex-native gate. Fable-medium Claude must receive the same class of task, choose by itself to launch Codex, and produce a Codex session that spawns and records at least one named profile from the managed agent set.

An untyped child with `agent_role = null` that inherits the root model and effort counts as a compatibility pass, including when Claude launches the Codex root, but it does not close either strict named-profile gate. A prompt that explicitly requests delegation is valid only for the compatibility control and never for an automatic-dispatch pass.

The 2026-07-12 run left both strict gates open. Sol-medium completed the implementation itself without a child, and two Fable-medium Claude attempts completed work directly without invoking Codex. Separate explicit controls confirmed that an untyped Codex child inherits `gpt-5.6-sol` at `medium` both directly and when launched through Claude.

## Recommended Next Steps

See `docs/tasks.md`.
