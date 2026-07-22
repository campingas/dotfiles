# Current State

Last updated: 2026-07-22

## Status

This repo now owns both shell dotfiles and coding-agent configuration.

Managed home-directory files live under `dots/`.

Claude global config lives at `dots/.claude/CLAUDE.md`.

Codex global config lives at `dots/.codex/AGENTS.md`.

Claude skills live under `dots/.claude/skills/` and are linked into `~/.claude/skills/` by `scripts/agents-syncs.sh`.

Codex skills live under `dots/.codex/skills/` and are linked into `~/.codex/skills/` by `scripts/agents-syncs.sh`.

Codex subagent profiles live under `dots/.codex/agents/` and are linked into `~/.codex/agents/` by `scripts/agents-syncs.sh`.

The repo-authored Claude skill is `html-planning`.

The repo-authored Claude `ExitPlanMode` hook enforces a recent session-scoped HTML plan artifact, while the `html-planning` skill separately gates successful Plan-Saver archival.

The repo-authored Codex skills are `repo-agents-md` and `html-planning`.

The mirrored `html-planning` skill uses one deterministic uploader for Claude, Codex, and compatible Bash-capable agents. Every generated artifact includes its agent name, is delivered locally, and is archived under a stable project/document identity so Plan-Saver appends versions instead of creating timestamped duplicates.

The repo-authored Codex agents are `lookup`, `investigate`, `implement`, `implement_deep`, and `review`.

## Durable Decisions

`AGENTS.md` stays short and routes to focused docs.

Repo-local `AGENTS.md` files should avoid duplicating global defaults.

`docs/bash.md` owns Bash fast-path details and validation.

`docs/agent-config.md` owns Claude, Codex, and skill sync behavior.

Claude uses Fable medium by default and raises it to high only for explicit quality-risk triggers. Every managed Codex profile uses GPT-5.6 Sol: lookup uses low effort and Fast speed, while investigation and implementation use medium effort at Standard speed and deep implementation and review use high effort at Standard speed. The evidence and refresh protocol live in `docs/gpt-5.6-agent-selection.md`.

Codex keeps integration in the root session, uses at most three independent read-only subagents and one writer, and controls overreach through explicit task envelopes and outcome-based stop conditions.

Codex uses native named-role spawning. `dots/.codex/AGENTS.md` owns orchestration policy, `dots/.codex/agents/*.toml` owns declared role runtime settings, and the app-managed `~/.codex/config.toml` owns global features and capacity. Deep implementation, more than three read-only subagents, multiple sequential delegated runs, and xhigh overrides remain confirmation-gated.

`docs/fleet-sync.md` owns remote-machine deployment expectations.

`scripts/fleet-sync.sh` provides an explicit-host, explicit-file, network-free preview and requires `--apply` before remote writes.

The local hardware inventory repo remains the source of truth for machine details; this public repo should not duplicate LAN details, host inventory, or private operational notes.

## Runtime State

The installed Codex CLI is 0.145.0. Its feature audit reports `multi_agent` and `multi_agent_v2` stable and enabled.

Current validation on 2026-07-22: after activating the all-Sol matrix, a fresh Sol-medium read-only root recorded `multi_agent_version = "v2"`; its isolated native child recorded `agent_role = "lookup"`, Sol low effort, and a read-only sandbox. The live `lookup.toml` separately confirms Fast speed because rollout records do not persist service tier. Root session `019f8833-33c4-7512-87e1-d2a50620d841` and child session `019f8833-68a0-73d3-a236-70e542743d11` prove the active lookup runtime and sandbox narrowing.

The first full-history Stage A spawn attempt was rejected before creating a child because a fork with full inherited history cannot override `agent_type`. The isolated retry selected the configured role, so global guidance now requires isolated forks for custom roles.

An earlier activation smoke selected a temporary Terra-low `lookup` profile under V2 but retained the active root's `workspace-write` sandbox. Keep that run as historical plumbing evidence only; the fresh read-only control above supersedes its sandbox result for the active all-Sol lookup profile.

The live app-managed configuration enables V2, sets `agents.max_threads = 4`, and keeps `agents.max_depth = 1`. The repository sync does not replace that file.

## Validated Runtime

The native role-plumbing control, native-only policy transition, active lookup-runtime check, fresh-root sandbox-narrowing check, and neutral automatic-selection check are complete.

The neutral check used root session `019f883f-ff31-7210-ba92-8b89fabc84de` and child session `019f8840-3ea8-7f42-b650-0f1da029c0c5`. A fresh Sol-medium read-only root received a real multi-file review prompt with no routing vocabulary, autonomously selected `review`, waited for it, and integrated its findings. The child recorded `agent_role = "review"`, Sol high effort, a read-only sandbox, and multi-agent V2; the live TOML separately confirms Standard speed.

The child found two migration consistency issues and one validation gap. The root corrected the retired dispatch-file cleanup, stale sync documentation, and missing isolated-HOME behavior test, then reran the affected validation.

Historical validation on 2026-07-12: a Sol-medium root completed the implementation itself without a child. Separate explicit controls confirmed that an untyped child inherited the root runtime. The retired Claude bridge experiments are retained only in the historical log in `docs/tasks.md`.

## Recommended Next Steps

No repository task is pending. Repeat the runtime controls only after a material Codex runtime or routing-policy change.
