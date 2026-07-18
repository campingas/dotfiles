---
name: codex-dispatch
description: Route one bounded independent task to a configured Codex profile with its pinned model, reasoning effort, sandbox, instructions, and evidence capture. Use when the root Codex decides that delegation or context isolation materially helps, when native named-role spawning is unavailable, or when the user asks Codex to propose, validate, or run a specific managed profile.
---

# Codex Dispatch

Keep requirements, integration, and final decisions in the root session. Use this skill only for one concrete independent objective.

## Select

Choose the lowest-effort profile that preserves the needed quality. Every profile uses GPT-5.6 Sol; low effort uses Fast speed, while medium and high effort use Standard speed.

- `lookup`: exact mechanical fact with no material judgment.
- `investigate`: read-only multi-file tracing or research.
- `implement`: normal bounded implementation.
- `implement_fast`: tightly specified high-effort implementation with minimal process overhead.
- `implement_deep`: security-sensitive, migration, cross-system, or materially ambiguous implementation.
- `review`: risk-triggered correctness, security, regression, and test-gap review.
- `review_fast`: narrow or fallback review.

Do not dispatch trivial work, tightly coupled work, or a task without a concrete independent output.

## Announce

Before running, state one short line:

```text
Dispatch: <profile> -> <model>/<effort>, <reason>.
```

Run automatically unless the selected profile is `implement_deep`, the task needs more than one delegated run, or an xhigh override is proposed. For those cases, present the choice and wait for confirmation. Pass `--confirmed` after approval for `implement_deep`; the launcher rejects that profile without it. Respect `no delegation`, `propose only`, or an explicit profile from the user.

## Run

Prepare a self-contained task envelope with the objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and stop conditions.

Preview a choice without launching:

```bash
UV_CACHE_DIR="/tmp/codex-uv-cache" uv run --no-cache --no-project \
  "$HOME/.codex/skills/codex-dispatch/scripts/dispatch.py" \
  --profile investigate \
  --cwd "$PWD" \
  --dry-run
```

Launch one delegated run:

```bash
UV_CACHE_DIR="/tmp/codex-uv-cache" uv run --no-cache --no-project \
  "$HOME/.codex/skills/codex-dispatch/scripts/dispatch.py" \
  --profile investigate \
  --cwd "$PWD" \
  --prompt-file "$PROMPT_FILE"
```

For a short envelope, pass it directly with `--prompt '...'` instead of creating a prompt file. Never use both inputs.

The command returns JSON containing the selected model, effort, service tier, fast-mode state, sandbox, elapsed time, session id, report, and evidence paths. Wait for it to finish, inspect the report and repository diff, verify material claims, and perform final validation in the root.

Do not edit concurrently with a writing profile. Do not describe an exec-backed delegated run as a native named-role child. Native profiles become authoritative only after session metadata proves a non-null `agent_role` and the expected runtime.
