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
- Keep integration and final decisions in the root. Run at most three independent read-only subagents concurrently and never more than one writing agent.
- Use native named-role spawning. The files under `~/.codex/agents/` are the configuration source of truth for each role's model, effort, service tier, sandbox, and instructions; verify the effective child runtime from persisted evidence when it matters.
- Every managed profile uses GPT-5.6 Sol. Use this direct-trigger map; the role TOMLs remain the executable configuration truth.

| Role | Effort | Speed | Direct trigger |
|------|--------|-------|----------------|
| `lookup` | low | Fast | Exact read-only fact with no material judgment |
| `investigate` | medium | Standard | Read-only multi-file tracing or research |
| `implement` | medium | Standard | Bounded implementation with clear acceptance criteria |
| `implement_deep` | high | Standard | Cross-system debugging, migration, security-sensitive work, or material ambiguity |
| `review` | high | Standard | Risk-triggered correctness, security, regression, edge-case, or test-gap review |

- When selecting a custom `agent_type`, use an isolated fork because full-history forks inherit the parent role and cannot override it.
- Automatically select exactly one matching profile for multi-file investigation or review, bounded implementation with clear acceptance criteria, or independent verification that benefits from isolated context. Use multiple read-only profiles only for concrete independent concerns that materially benefit from parallel work.
- Before delegation, announce `Dispatch: <profile>, <reason>.` Read only enough in the root to define the delegated envelope; do not complete the delegated objective first.
- Ask for confirmation before `implement_deep`, more than three read-only subagents, multiple sequential delegated runs, or an xhigh override. Respect `no delegation`, `propose only`, or an explicit profile from the user.
- Do not edit concurrently with a writing profile. Wait for the writer before review or integration when files overlap, inspect its evidence and diff, and perform final validation in the root.
- Add a separate review only for security, migrations, releases, cross-system behavior, weak validation, or an implementation that already required escalation.
- Give every child a concrete objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and conditions that require stopping instead of expanding scope.

## Stop Conditions

- Read broadly enough to understand the requested behavior, but edit only files directly required by it, its tests, and routed documentation.
- Stop when the acceptance criteria are satisfied and risk-proportional validation passes.
- Do not continue into optional cleanup, abstraction, style polishing, performance tuning, or adjacent fixes after completion.
- Do not broaden the requested behavior merely because a broader solution appears cleaner.
- Stop and report when completion requires new authority, a materially wider behavior boundary, overlapping user changes, unavailable credentials or dependencies, or unrelated failing validation.
- If the same failure remains after one targeted correction and no new evidence appears, stop the loop and return the evidence.
- Escalate effort once only when reasoning depth is the demonstrated limitation, not when the prompt, environment, or acceptance criteria are incomplete.
- End delegated work with changes, validation, unresolved risk, and intentionally excluded adjacent work.

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
