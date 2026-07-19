# Current State

Last updated: 2026-07-19

## Status

This repo now owns both shell dotfiles and coding-agent configuration.

Managed home-directory files live under `dots/`.

Claude global config lives at `dots/.claude/CLAUDE.md`.

Codex global config lives at `dots/.codex/AGENTS.md`.

Claude skills live under `dots/.claude/skills/` and are linked into `~/.claude/skills/` by `scripts/agents-syncs.sh`.

Codex skills live under `dots/.codex/skills/` and are linked into `~/.codex/skills/` by `scripts/agents-syncs.sh`.

Codex subagent profiles live under `dots/.codex/agents/` and are linked into `~/.codex/agents/` by `scripts/agents-syncs.sh`.

The repo-authored Claude skills are `codex-review`, `codex-implementation`, `codex-computer-use`, and `html-planning`.

The repo-authored Claude `ExitPlanMode` hook enforces a recent session-scoped HTML plan artifact, while the `html-planning` skill separately gates successful Plan-Saver archival.

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

The installed Codex CLI is 0.144.6, and its feature audit reports `multi_agent` stable and enabled. Current Codex documentation describes standalone custom-agent TOML loading and direct named-agent spawning, but no 0.144.6 native-role behavioral probe has run in this repo.

The last behavioral native-role probe remains Codex CLI 0.144.4. It produced an untyped child with `agent_role = null` that inherited the root runtime instead of selecting a custom profile. The `codex-dispatch` skill remains the production compatibility path and pins model, effort, speed, and sandbox explicitly until the revised staged validation supports a reviewed native-first transition.

The exec-backed dispatcher passes deterministic profile, model, effort, speed, sandbox, confirmation, concurrency, recursion, evidence, and live-sync checks. Focused tests cover all seven profiles and exact CLI arguments. Live Codex 0.144.5 implementation and review dispatches completed with GPT-5.6 Sol at medium effort and Standard speed; restricted roots can still block nested app-server initialization before the selected child starts.

Global Codex guidance carries the fixed all-Sol effort-and-speed map so proposal-only routing cannot invent a different model, effort, or speed.

## Pending Strong Validations

The revised sequence remains open: run the explicitly authorized Stage A native role-plumbing control, keep production routing exec-backed until it passes, make a separate reviewed native-first policy transition, run the neutral Stage B automatic-selection gate, and only then run Gate 2 from Claude. Follow `docs/tasks.md` for the evidence split and exact ordering.

Stage A is the sole validation-only exception to exec-backed dispatch. It explicitly requests the `lookup` native custom agent from a Sol-medium root and passes only when persisted evidence records `agent_role = "lookup"` plus the configured Sol model, low effort, and read-only sandbox. Record `agent_path` only for thread traceability. Speed is supported separately by profile and launcher configuration because rollout JSONL does not persist `service_tier`.

After the native-first policy transition, Stage B passes only when a Sol-medium Standard-speed root receives a naturally delegable plan or large task, chooses by itself to spawn a managed profile, and produces the same role, runtime, and separate speed evidence without task-prompt steering.

Gate 2 runs only after Stage B. Fable-medium Claude must receive the same class of neutral task, choose by itself to launch Codex, and produce a Codex session that automatically spawns and records at least one managed profile with matching runtime and separate speed evidence.

An untyped child with `agent_role = null` or inherited root runtime does not pass any revised stage or gate. Explicit delegation is valid only for the single Stage A plumbing control and invalidates Stage B or Gate 2.

The 2026-07-12 run left both strict gates open. Sol-medium completed the implementation itself without a child, and two Fable-medium Claude attempts completed work directly without invoking Codex. Separate explicit controls confirmed that an untyped Codex child inherits `gpt-5.6-sol` at `medium` both directly and when launched through Claude.

## Recommended Next Steps

See `docs/tasks.md`.
