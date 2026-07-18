# Current State

Last updated: 2026-07-18

## Status

This repo now owns both shell dotfiles and coding-agent configuration.

Managed home-directory files live under `dots/`.

Claude global config lives at `dots/.claude/CLAUDE.md`.

Codex global config lives at `dots/.codex/AGENTS.md`.

Claude skills live under `dots/.claude/skills/` and are linked into `~/.claude/skills/` by `scripts/agents-syncs.sh`.

Codex skills live under `dots/.codex/skills/` and are linked into `~/.codex/skills/` by `scripts/agents-syncs.sh`.

Codex subagent profiles live under `dots/.codex/agents/` and are linked into `~/.codex/agents/` by `scripts/agents-syncs.sh`.

The repo-authored Claude skills are `codex-review`, `codex-implementation`, `codex-computer-use`, and `html-planning`.

The repo-authored Codex skills are `repo-agents-md`, `codex-dispatch`, and `html-planning`.

The mirrored `html-planning` skill uses one deterministic uploader for Claude, Codex, and compatible Bash-capable agents. Every generated artifact includes its agent name, is delivered locally, and is archived under a stable project/document identity so Plan-Saver appends versions instead of creating timestamped duplicates.

The repo-authored Codex agents are `lookup`, `investigate`, `implement`, `implement_fast`, `implement_deep`, `review`, and `review_fast`.

## Durable Decisions

`AGENTS.md` stays short and routes to focused docs.

Repo-local `AGENTS.md` files should avoid duplicating global defaults.

`docs/bash.md` owns Bash fast-path details and validation.

`docs/agent-config.md` owns Claude, Codex, and skill sync behavior.

Claude uses Fable medium by default and raises it to high only for explicit quality-risk triggers. Every managed Codex profile uses GPT-5.6 Sol: low effort uses Fast speed, while medium and high effort use Standard speed. The evidence and refresh protocol for this decision live in `docs/gpt-5.6-agent-selection.md`.

Codex keeps integration in the root session, uses at most one active delegated run when isolation helps, and controls GPT-5.6 overreach through explicit task envelopes and outcome-based stop conditions.

Codex uses an automatic exec-backed dispatcher to apply the selected profile's pinned runtime until native named-role spawning passes strict validation. Deep implementation, multiple delegated runs, and xhigh overrides remain confirmation-gated.

`docs/fleet-sync.md` owns remote-machine deployment expectations.

The local hardware inventory repo remains the source of truth for machine details; this public repo should not duplicate LAN details, host inventory, or private operational notes.

## Known Issues

The last strict native-role probe, on Codex CLI 0.144.4, produced an untyped child with `agent_role = null` that inherited the root runtime instead of selecting a custom profile. The `codex-dispatch` skill remains the compatibility path and pins model, effort, speed, and sandbox explicitly. Revalidate native named roles on the installed CLI before replacing it.

The exec-backed dispatcher passes deterministic profile, model, effort, speed, sandbox, confirmation, concurrency, recursion, evidence, and live-sync checks. Focused tests cover all seven profiles and exact CLI arguments. Live Codex 0.144.5 implementation and review dispatches completed with GPT-5.6 Sol at medium effort and Standard speed; restricted roots can still block nested app-server initialization before the selected child starts.

Global Codex guidance carries the fixed all-Sol effort-and-speed map so proposal-only routing cannot invent a different model, effort, or speed.

## Pending Strong Validations

The two strict native named-role gates remain open. Run them in order using the routine in `docs/tasks.md`, and do not prompt either orchestrator to use Codex, subagents, profiles, or parallelism.

The Codex-native gate passes only when a Sol-medium Standard-speed root receives a naturally delegable plan or large task, chooses by itself to spawn a named profile from `dots/.codex/agents/`, and the child session records the profile name plus its configured model, effort, speed, and sandbox.

The Claude-to-Codex gate passes only after the Codex-native gate. Fable-medium Claude must receive the same class of task, choose by itself to launch Codex, and produce a Codex session that spawns and records at least one named profile with its configured model, effort, speed, and sandbox.

An untyped child with `agent_role = null` that inherits the root model, effort, speed, and sandbox counts as a compatibility pass, including when Claude launches the Codex root, but it does not close either strict named-profile gate. A prompt that explicitly requests delegation is valid only for the compatibility control and never for an automatic-dispatch pass.

The 2026-07-12 run left both strict gates open. Sol-medium completed the implementation itself without a child, and two Fable-medium Claude attempts completed work directly without invoking Codex. Separate explicit controls confirmed that an untyped Codex child inherits `gpt-5.6-sol` at `medium` both directly and when launched through Claude.

## Recommended Next Steps

See `docs/tasks.md`.
