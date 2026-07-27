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

## Package managers
- TypeScript/JavaScript: prefer `bun`, then `pnpm`. Never use `npm` or `yarn`.
- Cloned third-party repos: for upstream contributions, use the repo's own manager and lockfile; for local-only use, try `bun` first and fall back if incompatible. Never commit a swapped lockfile.
- Python: always use `uv` (and `uvx` for running tools).

## Shell Fast Paths
- For a local interactive agent or recovery shell, use `DOTFILES_AGENT_SHELL=1 bash -i`.
- For local one-off commands, prefer `bash -lc 'command here'`; when the command needs the managed Bash environment, tool paths, or CDPATH first, use `DOTFILES_AGENT_SHELL=1 bash -ic 'command here'`.
- The fast path loads core environment, tool paths, and CDPATH, then skips prompts, completions, and heavier interactive setup.

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


## Model routing

- Claude Code is the orchestrator harness for the Claude model. It owns conversation, planning, integration, and final decisions, and delegates only under the rules below.
- Use Opus 5 at high effort by default.
- Never use any Opus 4.8 or Sonnet model.

## Subagent delegation

- Claude-native subagents are allowed only for design or creative tasks, and must use Fable 5. Do not use them for implementation, investigation, or review.
- Delegate other worker tasks to Codex via `codex exec` in Bash.
- Optional pre-flight: for non-trivial or ambiguous tasks, first ask Codex which model and effort it intends (`codex exec -s read-only "Which model and reasoning effort would you use for this task, and why? <task>"`). Greenlight only if the intended choice matches the task class; otherwise name the correct model up front.
- Default call: `codex exec "<task envelope>"` from the target repo. Let the Codex root and native multi-agent V2 self-select the role and spawn GPT-5.6 Sol children. Do not pre-specify the model on the default path.
- Verify from the session rollout record what actually ran: `agent_role`, model, effort, sandbox, and `multi_agent_version`. A path, nickname, task label, or self-report is not evidence.
- Poor-choice handling: if Codex is running or ran with a model or effort wrong for the task class, stop that specific task immediately rather than letting it finish, then re-run naming the model: `codex exec -m gpt-5.6-sol -c model_reasoning_effort=<low|medium|high> -s <read-only|workspace-write> "<task>"`.
- Every delegation: report to the user the model, effort, and speed that ran. Speed is derived from the role's service tier (only `lookup` is Fast; all other roles are Standard) because it is not persisted in the rollout record.
- Respect concurrency limits: at most three independent read-only subagents concurrently, never more than one writer, and no concurrent writers on overlapping files.
- Give every delegated task an objective, acceptance criteria, behavior boundary, exclusions, required validation, completion condition, and stop conditions.
- The role TOMLs under `~/.codex/agents/` are the executable source of truth. This table is a reporting reference. See `docs/agent-config.md` and `docs/gpt-5.6-agent-selection.md` for the profile matrix and evidence rules.

| Role | Model | Effort | Speed | Sandbox |
|------|-------|--------|-------|---------|
| `lookup` | GPT-5.6 Sol | low | Fast | read-only |
| `investigate` | GPT-5.6 Sol | medium | Standard | read-only |
| `implement` | GPT-5.6 Sol | medium | Standard | workspace-write |
| `implement_deep` | GPT-5.6 Sol | high | Standard | workspace-write |
| `review` | GPT-5.6 Sol | high | Standard | read-only |

# Home hardware & network (pointer)

The full hardware inventory lives in a local hardware inventory repo.

Resolve it from `$HARDWARE_REPO` when set, otherwise use `$HOME/Repos/hardware` as the local convention.

When a task involves machines, network, peripherals, or IoT, read the relevant hardware inventory file first and log notable changes to the device maintenance log.

Do not duplicate machine inventory, LAN details, serials, or private operational notes in this public dotfiles repo.
