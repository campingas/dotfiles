# Agent Config

This repo tracks the user's global coding-agent configuration under `dots/`.

## Layout

`dots/.claude/CLAUDE.md` is the source for `~/.claude/CLAUDE.md`.

`dots/.claude/skills/` contains repo-authored Claude skills.

`dots/.claude/hooks/` contains repo-authored Claude lifecycle hooks.

`dots/.codex/AGENTS.md` is the source for `~/.codex/AGENTS.md`.

`dots/.codex/skills/` contains repo-authored Codex skills.

`dots/.codex/agents/` contains repo-authored Codex subagent profiles.

Root `AGENTS.md` is the repo-local routing contract for agents working in this checkout, and should not duplicate global defaults.

Root `CLAUDE.md` is a thin adapter that points Claude at root `AGENTS.md`.

## Sync

Run `scripts/agents-syncs.sh` after editing Claude config, Codex config, or repo-authored skills.

The script copies global adapter files into `~/.claude/` and `~/.codex/`.

The script does not copy or modify the app-managed `~/.codex/config.toml`. The Codex app owns global runtime settings such as feature flags, thread limits, and nesting depth.

The script links the HTML-planning hook into `~/.claude/hooks/` and idempotently merges its `ExitPlanMode` registration into the app-managed `~/.claude/settings.json` without replacing unrelated settings or hooks.

The script symlinks each directory under `dots/.claude/skills/` into `~/.claude/skills/`.

The script symlinks each directory under `dots/.codex/skills/` into `~/.codex/skills/`.

The script symlinks each TOML file under `dots/.codex/agents/` into `~/.codex/agents/`.

Codex discovers standalone custom-agent TOML files from `~/.codex/agents/`; do not add a duplicate registry to the app-managed `~/.codex/config.toml`.

The script prunes only stale skill symlinks that point back into this repo.

Skills that already exist in live skill directories but do not point into this repo are left untouched.

Agent profiles that already exist in the live agent directory but do not point into this repo are left untouched.

The Claude HTML-planning hook verifies only that the current session rendered an `html-planning-*.html` artifact recently. The skill remains responsible for verifying and reporting the separate Plan-Saver archive result.

## Codex Multi-Agent Split

Claude Code is the orchestrator harness. It prefers Fable 5 (or higher) as the default orchestrator model whenever available, and runs Opus 4.8 (or a higher Claude model) as the active stand-in while Fable is unavailable. It uses medium effort by default and raises to high only for security, consequential architecture, migrations, releases, cross-system debugging, or an incomplete medium result.

The Claude model policy lives in `dots/.claude/CLAUDE.md` under "Model routing", and the Claude-to-Codex delegation policy under "Subagent delegation (Codex)".

Codex delegates selectively when a bounded independent task benefits from parallel work or context isolation. Simple work uses no delegated process.

`dots/.codex/AGENTS.md` defines concise orchestration policy: when to delegate, concurrency limits, confirmation gates, task-envelope requirements, and root ownership.

`dots/.codex/agents/*.toml` is the executable per-role configuration truth for model, effort, service tier, sandbox, and role instructions. `dots/.codex/AGENTS.md` keeps only the compact direct-trigger map; verify the effective child runtime from persisted evidence when it matters.

The app-managed `~/.codex/config.toml` owns global feature and capacity settings. This repo documents the expected boundary but does not install or replace that file.

The root Codex session remains the orchestrator. Native named-role spawning is the only managed delegation path, and an isolated fork is required when selecting a custom `agent_type` because a full-history fork inherits the parent role.

The live app-managed `~/.codex/config.toml` enables `multi_agent_v2`, caps open agent threads at four, and keeps nesting depth at one. The repo does not copy or replace that file.

Run at most three independent read-only subagents concurrently and never more than one writing agent. Do not run concurrent writers against overlapping files.

| profile | model | effort | speed | use |
|---------|-------|--------|-------|-----|
| `lookup` | GPT-5.6 Sol | low | Fast | Exact mechanical facts with no material judgment |
| `investigate` | GPT-5.6 Sol | medium | Standard | Read-only multi-file tracing and research |
| `implement` | GPT-5.6 Sol | medium | Standard | Normal bounded implementation |
| `implement_deep` | GPT-5.6 Sol | high | Standard | Cross-system debugging, migrations, security-sensitive work, and material ambiguity |
| `review` | GPT-5.6 Sol | high | Standard | Risk-triggered correctness, security, regression, and test-gap review |

Sol xhigh is a one-off override only after a failed Sol-high attempt or for a genuinely long-horizon frontier task, with the reason recorded. Max effort is not allowed.

See `docs/gpt-5.6-agent-selection.md` for the model boundary, concurrency policy, native validation, evidence limits, and local evaluation protocol.

Every delegated task defines an objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and stop conditions. Agents stop after acceptance criteria and risk-proportional validation pass, without optional cleanup, abstraction, polishing, tuning, adjacent fixes, or repeated failure loops.

Native routing automatically selects one matching role for qualifying bounded work and may use multiple read-only roles only for concrete independent concerns. Global guidance requires confirmation for `implement_deep`, more than three read-only subagents, multiple sequential delegated runs, or an xhigh override. A user may override the default with `no delegation`, `propose only`, or an explicit profile.

Current validation on 2026-07-22: after activating the all-Sol matrix, Codex CLI 0.145.0 passed the native role-plumbing control with `multi_agent_version = "v2"`. The isolated child recorded `agent_role = "lookup"`, GPT-5.6 Sol, low effort, and a read-only sandbox. Root session `019f8833-33c4-7512-87e1-d2a50620d841` and child session `019f8833-68a0-73d3-a236-70e542743d11` validate the active lookup runtime and fresh-root sandbox narrowing. The live profile separately confirms Fast speed because rollout records do not persist service tier.

An earlier activation smoke selected a temporary Terra-low `lookup` profile under V2 but retained the root's `workspace-write` sandbox. It remains historical plumbing evidence only; the fresh read-only control supersedes its sandbox result for the active all-Sol lookup profile.

Neutral automatic selection passed on 2026-07-22. Root session `019f883f-ff31-7210-ba92-8b89fabc84de` received a real multi-file review prompt with no routing vocabulary and autonomously selected `review`. Child session `019f8840-3ea8-7f42-b650-0f1da029c0c5` recorded the managed role, GPT-5.6 Sol, high effort, a read-only sandbox, and multi-agent V2; Standard speed is confirmed separately by `review.toml`.

## Claude to Codex Delegation

Claude Code is the orchestrator harness and delegates all worker tasks to Codex through `codex exec` in Bash. The Claude `Agent` tool only spawns Claude subagents, so it is not the delegation path. The full policy lives in `dots/.claude/CLAUDE.md` under "Subagent delegation (Codex)".

Optional pre-flight: for non-trivial or ambiguous tasks, ask Codex which model and effort it intends before greenlighting: `codex exec -s read-only "Which model and reasoning effort would you use for this task, and why? <task>"`. Proceed only if the intended choice matches the task class; otherwise name the correct model up front.

Default call: `codex exec "<task envelope>"`. The fresh Codex root reasons at the app default (`gpt-5.6-sol`, high effort) and native multi-agent V2 may spawn a GPT-5.6 Sol role child. Do not pre-specify the model on the default path.

Verification: `codex exec` prints the model, effort, sandbox, and session id, and the session rollout under `~/.codex/sessions/<yyyy>/<mm>/<dd>/rollout-*-<session-id>.jsonl` persists `model`, `effort`, `sandbox_policy`, `multi_agent_version`, and `agent_role` when a role child ran. A path, nickname, task label, or self-report is not evidence. Speed is not persisted and is derived from the role service tier (only `lookup` is Fast).

Correction: if Codex is running or ran with a model or effort wrong for the task class, stop that specific task immediately rather than letting it finish, then re-run naming the model: `codex exec -m gpt-5.6-sol -c model_reasoning_effort=<low|medium|high> -s <read-only|workspace-write> "<task>"`.

Report to the user the model, effort, and speed that ran on every delegation.

Delegation validation on 2026-07-22 with Codex CLI 0.145.0: a neutral lookup-class prompt on the default path (session `019f887e-7aaa-7b42-8b27-6bf2c696acd8`) ran as a fresh root at GPT-5.6 Sol, high effort, read-only sandbox, `multi_agent_version = "v2"`, and answered directly without spawning a child. High effort on a trivial lookup is the "poor choice" case: the correction re-run (session `019f887e-ea0b-7d20-8377-cfefe2e66e30`) with an explicit `-m gpt-5.6-sol -c model_reasoning_effort=low` recorded low effort and a read-only sandbox, confirming the model-override path.

## Public Repo Safety

Do not duplicate machine inventory, LAN details, serials, or private operational notes here.

Refer to the local hardware inventory repo generically when hardware context is needed.

Keep global agent instructions concise and public-safe.

Use the Codex `repo-agents-md` skill when creating or refreshing repo-local `AGENTS.md` files.
