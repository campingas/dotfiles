# Agent Config

This repo tracks the user's global coding-agent configuration under `dots/`.

## Layout

`dots/.claude/CLAUDE.md` is the source for `~/.claude/CLAUDE.md`.

`dots/.claude/skills/` contains repo-authored Claude skills.

`dots/.claude/hooks/` contains repo-authored Claude lifecycle hooks.

`dots/.codex/AGENTS.md` is the source for `~/.codex/AGENTS.md`.

`dots/.codex/skills/` contains repo-authored Codex skills.

`dots/.codex/agents/` contains repo-authored Codex subagent profiles.

`dots/.codex/dispatch.toml` contains the global fallback-dispatch policy.

Root `AGENTS.md` is the repo-local routing contract for agents working in this checkout, and should not duplicate global defaults.

Root `CLAUDE.md` is a thin adapter that points Claude at root `AGENTS.md`.

## Sync

Run `scripts/agents-syncs.sh` after editing Claude config, Codex config, or repo-authored skills.

The script copies global adapter files into `~/.claude/` and `~/.codex/`.

The script copies `dots/.codex/dispatch.toml` into `~/.codex/dispatch.toml` without modifying the app-managed `~/.codex/config.toml`.

The script links the HTML-planning hook into `~/.claude/hooks/` and idempotently merges its `ExitPlanMode` registration into the app-managed `~/.claude/settings.json` without replacing unrelated settings or hooks.

The script symlinks each directory under `dots/.claude/skills/` into `~/.claude/skills/`.

The script symlinks each directory under `dots/.codex/skills/` into `~/.codex/skills/`.

The script symlinks each TOML file under `dots/.codex/agents/` into `~/.codex/agents/`.

Codex discovers standalone custom-agent TOML files from `~/.codex/agents/`; do not add a duplicate registry to the app-managed `~/.codex/config.toml`.

The script prunes only stale skill symlinks that point back into this repo.

Skills that already exist in live skill directories but do not point into this repo are left untouched.

Agent profiles that already exist in the live agent directory but do not point into this repo are left untouched.

The Claude HTML-planning hook verifies only that the current session rendered an `html-planning-*.html` artifact recently. The skill remains responsible for verifying and reporting the separate Plan-Saver archive result.

## Subagent Dispatch

Claude uses fable-5 at medium effort by default and raises it to high only for security, consequential architecture, migrations, releases, cross-system debugging, or an incomplete medium result. Opus 4.8 high is the availability fallback.

The full Claude routing and dispatch policy lives in `dots/.claude/CLAUDE.md` under "Model routing and automatic dispatch".

Codex delegates selectively when a bounded independent task benefits from context isolation. Simple work uses no delegated process, and the exec-backed compatibility path permits exactly one active delegated process at a time.

The root Codex session remains the orchestrator. When the installed runtime exposes named roles, it must select a matching custom profile instead of creating an untyped child.

Until native role plumbing passes Stage A and a separate reviewed native-first policy transition is made, the root uses the `codex-dispatch` skill. The skill launches a separate `codex exec` process with the selected profile's model, reasoning effort, speed, sandbox, and prompt-layer workflow instructions, then returns the report and session evidence to the root.

Exactly one validation-only exception may bypass `codex-dispatch`: an explicitly requested native custom-agent control for one managed role. It is plumbing evidence only, cannot count as automatic selection, and does not change production routing by itself.

| profile | model | effort | speed | use |
|---------|-------|--------|-------|-----|
| `lookup` | GPT-5.6 Sol | low | Fast | Exact mechanical facts with no material judgment |
| `investigate` | GPT-5.6 Sol | medium | Standard | Read-only multi-file tracing and research |
| `implement` | GPT-5.6 Sol | medium | Standard | Normal bounded implementation |
| `implement_fast` | GPT-5.6 Sol | high | Standard | Tightly specified work with minimal process overhead |
| `implement_deep` | GPT-5.6 Sol | high | Standard | Cross-system debugging, migrations, security-sensitive work, and material ambiguity |
| `review` | GPT-5.6 Sol | medium | Standard | Risk-triggered correctness, security, regression, and test-gap review |
| `review_fast` | GPT-5.6 Sol | high | Standard | Narrow or fallback review |

Sol xhigh is a one-off override only after a failed Sol-high attempt or for a genuinely long-horizon frontier task, with the reason recorded. Max effort is not allowed.

See `docs/gpt-5.6-agent-selection.md` for the dated benchmark evidence, quality-per-token reasoning, limitations, and local validation protocol behind this all-Sol matrix.

Every delegated task defines an objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and stop conditions. Agents stop after acceptance criteria and risk-proportional validation pass, without optional cleanup, abstraction, polishing, tuning, adjacent fixes, or repeated failure loops.

The fallback policy is automatic for one bounded run. The launcher enforces confirmation for `implement_deep` and prevents concurrent delegated processes. Global guidance requires confirmation before multiple sequential runs or an xhigh override. A user may override the default with `no delegation`, `propose only`, or an explicit profile.

The last behavioral native-role probe, on Codex CLI 0.144.4, still recorded `agent_role = null` and inherited the root runtime. The installed 0.144.6 feature audit supports running the Stage A control, but keep using the exec-backed dispatcher until Stage A proves a non-null managed role plus the configured model, effort, and sandbox and a separate reviewed native-first policy transition is made. Record `agent_path` only as thread traceability, not role evidence. Treat speed as profile and launcher configuration evidence because rollout JSONL does not persist `service_tier`.

## Public Repo Safety

Do not duplicate machine inventory, LAN details, serials, or private operational notes here.

Refer to the local hardware inventory repo generically when hardware context is needed.

Keep global agent instructions concise and public-safe.

Use the Codex `repo-agents-md` skill when creating or refreshing repo-local `AGENTS.md` files.
