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

## Subagent Dispatch

- Delegate selectively when a bounded independent task benefits from parallel work or context isolation.
- Do not delegate trivial work, tightly coupled changes, or tasks without a concrete independent objective.
- Run no more than three child agents concurrently and no more than one writing agent at a time.
- Give each child a clear objective, constraints, expected output, and file ownership; keep integration and final decisions with the main agent.
- Use `high` reasoning effort by default. Use `medium` only when it is obvious that the task is straightforward, low-risk, and well-scoped; when uncertain, use `high`.
- Never use reasoning effort other than `medium` or `high`.
- Use `scout` for simple targeted discovery, `explorer` for substantial read-only analysis, `worker` for normal implementation, `expert_worker` for complex implementation, and `reviewer` for correctness or security review.
- Fall back from `expert_worker` to `worker` to `compat_worker`, from `reviewer` to `compat_reviewer`, and from `explorer` to `scout`; continue in the main thread if no suitable profile is available.
- Use only the model profiles listed above; do not select older unlisted models.

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

## Repository AGENTS.md

- Keep repo-local `AGENTS.md` files specific to that repo.
- Do not repeat global defaults unless the repo may be used without this global config or needs a stricter local rule.
- Prefer routing to focused docs over front-loading long architecture, command, or history sections.
- Preserve enough context for safe work: read order, repo-specific commands, safety boundaries, and validation.

# Home hardware & network (pointer)

The full hardware inventory lives in a local hardware inventory repo.

Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention.

When a task involves machines, network, peripherals, or IoT, read the relevant hardware inventory file first and log notable changes to the device maintenance log.

Do not duplicate machine inventory, LAN details, serials, or private operational notes in this public dotfiles repo.
