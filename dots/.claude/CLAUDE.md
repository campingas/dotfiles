## Prompt Quality

- If a request is ambiguous or underspecified enough to materially affect the result, propose a clearer version and ask me to confirm before proceeding.
- Make suggested prompts specific about the goal, scope, constraints, and expected outcome.
- For complex tasks, recommend a short step-by-step plan when it would improve clarity.

## Git branches

- Before editing, inspect the current branch and worktree.
- Preserve uncommitted changes. Ask how to proceed only when they overlap the requested work, and never commit them without explicit approval.
- For implementation work, create a dedicated branch with a descriptive conventional prefix such as `feat/`, `fix/`, `docs/`, or `chore/`, unless I explicitly ask you to remain on the current branch.

## Code Style
- Always strive for concise, simple solutions.
- If a problem can be solved in a simpler way, propose it.

## General preferences
- If asked to do too much work at once, stop and state that clearly.
- If computer use is helpful for completing or verifying work, shell out to Codex for it.

## Package managers
- TypeScript/JavaScript: prefer `bun`, then `pnpm`. Never use `npm` or `yarn`.
- Cloned third-party repos: for upstream contributions, use the repo's own manager and lockfile; for local-only use, try `bun` first and fall back if incompatible. Never commit a swapped lockfile.
- Python: always use `uv` (and `uvx` for running tools).

## Shell Fast Paths
- For a local interactive agent or recovery shell, use `DOTFILES_AGENT_SHELL=1 bash -i`.
- For local one-off commands, prefer `bash -lc 'command here'`; when the command needs the managed Bash environment, tool paths, or CDPATH first, use `DOTFILES_AGENT_SHELL=1 bash -ic 'command here'`.
- The fast path loads core environment, tool paths, and CDPATH, then skips prompts, completions, tmux auto-attach, and heavier interactive setup.

## Core Working Rules

- Read directly related files before editing; do not infer behavior from filenames alone.
- Implement only code used by the requested behavior; do not add speculative helpers or abstractions.
- When changing behavior, inspect relevant tests, config, adjacent modules, and routed documentation.
- Prefer existing codebase patterns and utilities over new abstractions.
- Keep changes scoped to the requested behavior; note unrelated issues separately.
- Do not revert user changes unless explicitly requested.
- Do not commit unless explicitly asked.
- Do not add production behavior solely to satisfy tests. When testability requires a seam, prefer a production-useful interface over test-only branches or hooks.
- Use conventional commit messages if a commit is requested.
- Never include agent branding, assistant names, or co-authorship metadata unless explicitly requested.

## Documentation

- Use single-line paragraphs in Markdown.
- Keep headings concise.
- Update routed docs when behavior, architecture, or workflows change.
- Use plain ASCII punctuation. Do not use em dashes or en dashes; use commas, periods, parentheses, colons, or hyphens instead.


## Model routing and automatic dispatch

Protect both Claude and Codex subscription limits. Prefer the lowest configuration that preserves the needed quality, and escalate only for explicit risk or demonstrated reasoning limits.

| lane | default | fallback |
|------|---------|----------|
| Claude (main thread, integration, final decisions) | fable-5 at medium effort | fable-5 at high effort, then opus-4.8 high if Fable is unavailable |
| Codex bounded work | Sol at the selected profile's pinned effort and speed (low/Fast, medium/Standard, high/Standard) | Sol xhigh as a one-off override after a failed Sol-high run, with the reason recorded |

Claude model policy:
- Use fable-5 at medium effort by default for requirements, planning, integration, final decisions, and small tightly coupled edits.
- Raise Fable to high only for security-sensitive reasoning, architecture with expensive consequences, migrations, release decisions, cross-system debugging, or an incomplete medium result.
- Fall back to opus-4.8 at high effort only when Fable is unavailable. Do not use other Claude models or effort levels except for the thin Codex wrapper below.
- Prefer Codex for bounded implementation and verification, but do not delegate a trivial task merely to save main-thread tokens.
- Anything user-facing (UI, copy, API design) or taste-critical stays on the Claude lane.
- Escalate one level without asking when validation or concrete evidence shows a reasoning-quality gap. Do not restart on a stronger lane because the prompt or environment was incomplete.

Automatic dispatch (mirror of the Codex dispatch rules):
- On every prompt, assess whether bounded independent subtasks benefit from parallel work or context isolation, and delegate them without being asked.
- Do not delegate trivial work, tightly coupled changes, or tasks without a concrete independent objective.
- Use no child for simple work and one child by default when isolation helps. Use two only for clearly independent objectives and three only for an explicit rush trigger; never run more than one writer.
- Give each child an objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and stop conditions; keep integration and final decisions in the main thread.
- Use the defined Codex profiles, all GPT-5.6 Sol varying only effort and speed: `lookup`, `investigate`, `implement`, `implement_fast`, `implement_deep`, `review`, and `review_fast`. They live in `dots/.codex/agents/*.toml` (synced to `~/.codex/agents/`) and are documented in `docs/agent-config.md`.
- Add a separate review only for security, migrations, releases, cross-system behavior, weak validation, or an implementation that required escalation.
- Require delegated work to stop after acceptance criteria and risk-proportional validation pass, without adjacent cleanup, abstraction, polishing, tuning, or repeated failure loops.

Codex mechanics:
- Codex is GPT-5.6 Sol only. Never route Codex work to Terra or any other model. Vary effort and speed by choosing the profile, not the model. `~/.codex/config.toml` defaults to gpt-5.6-sol high for bare `codex exec`; the launcher below overrides effort and speed per profile.
- To spawn a defined Codex subagent, use the `codex-dispatch` launcher, which pins the profile's Sol model, effort, speed, sandbox, and instructions:
  `uv run --no-cache --no-project "$HOME/.codex/skills/codex-dispatch/scripts/dispatch.py" --profile <name> --cwd "$PWD" --prompt-file <file>`
  Add `--dry-run` to preview the resolved model, effort, speed, and sandbox without launching. `implement_deep`, more than one delegated run, or an xhigh override need confirmation first, and `implement_deep` also requires `--confirmed`.
- For higher-level entry points use the codex-implementation, codex-review, and codex-computer-use skills; they wrap the same Sol-only Codex CLI.
- Codex runs can exceed Bash's 10-minute timeout: run in the background and poll for the report file, or raise the timeout.
- Parallel Codex implementation agents must use `isolation: 'worktree'` so codex edits don't collide in the shared checkout.
- Native named-role selection under `codex exec` is still unproven on the installed CLI (0.144.6, `agent_role = null`). Keep using the exec-backed launcher and do not claim a native role ran unless session metadata proves a non-null `agent_role` plus the expected runtime.

Codex inside workflows and subagents (the Agent `model` parameter only takes Claude models, so use a wrapper):
- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt tells it to write a self-contained task envelope, run the `codex-dispatch` launcher with the chosen profile via Bash, and return the launcher's JSON report (use `schema` on the wrapper for structured output). This is the one allowed use of sonnet: the wrapper is a dumb shell and the real worker is Sol.
- Always label these agents with a `codex:` prefix, e.g. `{label: 'codex:review-auth'}`. The workflow UI shows the wrapper's Claude model, so the label is the only indication the real worker is Codex.
- Workflow token budgets only count Claude tokens; codex work is free and invisible to `budget.spent()`.

# Home hardware & network (pointer)

The full hardware inventory lives in a local hardware inventory repo.

Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention.

When a task involves machines, network, peripherals, or IoT, read the relevant hardware inventory file first and log notable changes to the device maintenance log.

Do not duplicate machine inventory, LAN details, serials, or private operational notes in this public dotfiles repo.
