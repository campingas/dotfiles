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

Cost context: OpenAI is near-free for me due to a deal, so Codex work is effectively free; Claude tokens are the scarce resource.

| lane | default | fallback |
|------|---------|----------|
| Claude (main thread, taste-critical work, integration, final decisions) | fable-5 at high effort | opus-4.8 at high effort |
| Codex dispatch (bulk implementation, review, investigation, verification) | gpt-5.6 family via Codex's own agent profiles | gpt-5.5 compat |

Claude model policy:
- Use fable-5 at high effort by default. Fall back to opus-4.8 at high effort only when fable-5 is unavailable.
- Never use any other Claude model or effort level (no sonnet, no haiku, no low or medium effort). Sole exception: the thin Codex wrapper below.
- Preference order for delegated work: fable-5 high, then Codex dispatch, then opus-4.8 high. Prefer handing work to Codex over spending Opus on it.
- Anything user-facing (UI, copy, API design) or taste-critical stays on the Claude lane.
- Standing permission: if delegated output does not meet the bar, redo it on a smarter lane without asking. Judge the output, not the price tag.

Automatic dispatch (mirror of the Codex dispatch rules):
- On every prompt, assess whether bounded independent subtasks benefit from parallel work or context isolation, and delegate them without being asked.
- Do not delegate trivial work, tightly coupled changes, or tasks without a concrete independent objective.
- Run no more than three child agents concurrently and no more than one writing agent at a time.
- Give each child a clear objective, constraints, expected output, and file ownership; keep integration and final decisions in the main thread.
- Route bulk or mechanical subtasks (clear-spec implementation, data analysis, migrations, independent review passes) to Codex; it dispatches internally to its own matrix (scout, explorer, worker, expert_worker, reviewer per `~/.codex/AGENTS.md`), so hand it the task, not a model choice.

Codex mechanics:
- Codex is reached through the Codex CLI: `codex exec` / `codex review` (my `~/.codex/config.toml` defaults to gpt-5.6-sol at high effort).
- Use the codex-implementation, codex-review, and codex-computer-use skills; for work they don't cover (investigation, data analysis), run `codex exec -s read-only` directly with a self-contained prompt.
- Codex runs can exceed Bash's 10-minute timeout: pass an explicit timeout, or run in the background and poll for the report file.
- Parallel Codex implementation agents must use `isolation: 'worktree'` so codex edits don't collide in the shared checkout.

Codex inside workflows and subagents (the model parameter only takes Claude models, so use a wrapper):
- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec` via Bash, and return the report (use `schema` on the wrapper to get structured output back). This is the one allowed use of sonnet: the wrapper is a dumb shell and the real worker is Codex.
- Always label these agents with a `codex:` prefix, e.g. `{label: 'codex:review-auth'}`. The workflow UI shows the wrapper's Claude model, so the label is the only indication the real worker is Codex.
- Workflow token budgets only count Claude tokens; codex work is free and invisible to `budget.spent()`.

# Home hardware & network (pointer)

The full hardware inventory lives in a local hardware inventory repo.

Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention.

When a task involves machines, network, peripherals, or IoT, read the relevant hardware inventory file first and log notable changes to the device maintenance log.

Do not duplicate machine inventory, LAN details, serials, or private operational notes in this public dotfiles repo.
