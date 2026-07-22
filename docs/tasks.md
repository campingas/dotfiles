# Tasks

This file tracks current dotfiles work so the user and agents can see what changed and what remains open.

## Current Focus

Keep this repo as the single source for shell dotfiles plus coding-agent configuration.

Keep default context small: `AGENTS.md` routes to focused docs instead of carrying full operational detail.

Keep fleet updates confirmation-gated. Agents may prepare a deployment plan, but they must wait for confirmation before copying files to remote machines.

## Open Items

None. The local policy sync, neutral native automatic-selection check, and dry-run-first fleet helper are complete and validated.

## Native Multi-Agent Validation

The explicit role-plumbing control and neutral automatic-selection check passed, and the repo policy is native-only. Preserve the prompt, configuration evidence, and relevant Codex rollout JSONL files when repeating the protocol after a material runtime or policy change.

### Test Task

Choose a real approved plan or large bounded task with clear acceptance criteria and at least two independent concerns, such as impact analysis plus implementation, or implementation plus risk review. Keep it large enough that delegation is useful but bounded enough for one final owner.

Use a neutral prompt such as:

```text
Implement the approved plan at <path> end to end. Preserve unrelated changes, follow repository instructions, run the required validation, and stop when the acceptance criteria pass. Report changed files, validation, remaining risk, and intentionally excluded adjacent work.
```

Do not mention Codex, agents, subagents, profile names, models, delegation, fan-out, or parallelism in the task prompt. Those terms invalidate the automatic-selection check.

### Completed Role-Plumbing Controls

Current result from 2026-07-22: after activating the all-Sol matrix, Codex CLI 0.145.0 with `multi_agent_v2` enabled launched an isolated native child with `agent_role = "lookup"`, Sol low effort, and a read-only sandbox. The root recorded Sol medium effort and a read-only sandbox. Root session `019f8833-33c4-7512-87e1-d2a50620d841` and child session `019f8833-68a0-73d3-a236-70e542743d11` validate the active lookup runtime and fresh-root sandbox narrowing.

The first full-history spawn attempt was rejected before creating a child because it tried to override the inherited parent role. The isolated retry selected the configured role successfully.

The live `lookup.toml` separately confirms Fast speed because rollout records do not persist service tier. This explicitly steered control proves native role plumbing and the active lookup runtime, but not automatic role selection.

### Completed Automatic Selection Check

On 2026-07-22, a fresh read-only Sol-medium root received a real multi-file review task with no routing vocabulary in its prompt. It autonomously selected `review`, waited for the child, integrated its findings, and completed read-only validation.

Root session `019f883f-ff31-7210-ba92-8b89fabc84de` recorded Sol medium, a read-only sandbox, and multi-agent V2. Child session `019f8840-3ea8-7f42-b650-0f1da029c0c5` recorded `agent_role = "review"`, Sol high, a read-only sandbox, and multi-agent V2. The live `review.toml` separately confirms Standard speed because rollout records do not persist service tier.

The exact neutral prompt was:

```text
Review the current uncommitted configuration migration for consistency across all changed files. Do not edit files. Inspect the diff and run read-only validation. Report concrete correctness, regression, stale-reference, and missing-validation gaps with file evidence, or state that none were found. Stop after the changed behavior and directly affected documentation are assessed.
```

The child found the retired dispatch-file cleanup gap, the stale `scripts/README.md` wording, and the missing isolated-HOME sync behavior test. All three findings were corrected and validated in the owning root.

### Repeat Protocol

1. Activate the repo-managed policy and five role TOMLs through a separate confirmed sync task, then record the Codex CLI version and the relevant app-managed global settings without replacing them.
2. Start a fresh root on a clean disposable branch or worktree with the neutral test prompt.
3. Let the root plan and execute without steering it toward delegation or sending agent-related follow-up instructions.
4. Find the new root and child rollout files, then confirm that each child records a managed non-null `agent_role` and matches the selected TOML's model, effort, and sandbox. Record `agent_path` only for traceability.
5. Confirm the root selected the role without explicit steering, waited for the child, integrated its evidence, respected the one-writer rule, and completed the requested validation.

The check passes only when automatic named-role selection and the configured child runtime are both proven. A task with no child, explicit steering, an untyped child, or inherited root runtime is a failure. The completed control above meets these criteria.

The separate explicit activation smoke used session `019f87f6-d763-7a62-8350-dc6821e54f1b`. It passed role, model, effort, and V2 checks for the then-current matrix (`lookup`, Terra, low, V2) but did not prove sandbox narrowing because the child retained the active root's `workspace-write` policy instead of the TOML's declared `read-only` setting. It is historical plumbing evidence, not validation of the active all-Sol matrix.

### Evidence Command

Use the following shape for each candidate rollout file:

```bash
jq -c 'select(.type == "session_meta" or .type == "turn_context") | {type, originator: .payload.originator, source: .payload.source, agent_role: (try .payload.source.subagent.thread_spawn.agent_role catch null), agent_path: (.payload.agent_path // (try .payload.source.subagent.thread_spawn.agent_path catch null)), model: .payload.model, effort: .payload.effort, sandbox_policy: .payload.sandbox_policy, multi_agent_version: .payload.multi_agent_version}' <rollout.jsonl>
```

Persisted rollout evidence covers originator/source, role, model, effort, sandbox, and multi-agent version. Record agent path only for traceability, and record speed from the profile TOML and app-managed configuration instead of claiming that `service_tier` is persisted.

Record the task prompt, CLI version, root session id, child session ids, selected role names, effective models, efforts, configured speeds, sandboxes, validation results, and final pass or failure reason in this section after each test.

### Timed Log

The table below is historical evidence only, not active workflow guidance. Times without a date are Asia/Ho_Chi_Minh on 2026-07-12. Those results predate the current five-role native fleet. Test fixtures were disposable, and no test implementation was retained in this repository.

| Time | Test | Runtime path | Result | Short result |
|------|------|--------------|--------|--------------|
| 14:00 (148s) | Gate 1, automatic build | Codex Sol-medium -> no child | ❌ Strict fail | Sol completed the task alone. |
| 14:03 (227s) | Gate 2, automatic build | Claude Fable-medium -> no Codex | ❌ Strict fail | Claude worked alone; Bash was blocked. |
| 14:08 (74s) | Gate 2, automatic review | Claude Fable-medium -> no Codex | ❌ Strict fail | Clean retry; Claude still worked alone. |
| 14:10 (57s) | Inheritance control | Codex Sol-medium -> Sol-medium | ✅ Compat pass | Untyped child inherited root runtime. |
| 14:11 (110s) | Claude inheritance control | Claude Fable-medium -> Codex Sol-medium -> Sol-medium | ✅ Compat pass | Inheritance worked; Claude hit its budget cap after verification. |
| 15:15 (92s) | Dispatcher smoke, automatic review | Codex Sol-medium -> no delegated run | ❌ Fail | Root reviewed alone and found dispatcher policy gaps; gaps were fixed. |
| 15:19 (7s) | Dispatcher smoke retry | Codex Sol-medium -> usage limit | ⚠ Blocked | Model did not begin reasoning; retry after 15:53. |
| 15:19 (5s) | Lower-cost retry | Codex Terra-medium -> usage limit | ⚠ Blocked | Global limit confirmed; no further model retries. |
| 15:19 (<1s) | Live policy preview | Dispatcher -> Terra-medium | ✅ Config pass | Synced runtime mapping and deep confirmation guard passed. |
| 15:59 | Dispatcher smoke | Codex Sol-medium/read-only -> blocked | ❌ Sandbox fail | Root selected `investigate`; parent blocked dispatcher temp writes. |
| 16:02 | Dispatcher smoke | Codex Sol-medium/read-only -> blocked | ❌ Sandbox fail | `/tmp` fix reached launcher; parent still blocked evidence creation. |
| 16:05 | Dispatcher smoke | Codex Sol-medium/workspace-write -> blocked | ❌ Sandbox fail | Nested Codex app-server initialization was denied. |
| 16:09 (244s) | Dispatcher smoke | Codex Sol-medium -> Terra-medium | ✅ Compat pass | Automatic `investigate`; pinned read-only child completed in 137s. |
| 16:21 (96s) | Proposal-only control | Codex Sol-medium -> no launch | ❌ Route fail | Correct profile, but it invented `gpt-5.4/high`; mapping was tightened. |
| 16:24 (8s) | Proposal-only retry | Codex Sol-medium -> no launch | ✅ Policy pass | Proposed `investigate` -> Terra-medium; zero command executions. |
| 2026-07-22 04:51 | Stage A V2 control | Codex Sol-medium -> native `lookup` Sol-low | ✅ Strict pass | Isolated child recorded `agent_role = "lookup"`, matching effort and sandbox, with `multi_agent_version = "v2"`. |
| 2026-07-22 12:01 | Active lookup control | Codex Sol-medium/read-only -> native `lookup` Sol-low/read-only | ✅ Runtime pass | Fresh-root child matched the active role, model, effort, sandbox, and V2 metadata; Fast speed is configuration evidence. |
| 2026-07-22 12:15 | Neutral automatic review | Codex Sol-medium/read-only -> native `review` Sol-high/read-only | ✅ Strict pass | An unsteered real review selected the managed role, matched runtime metadata, and returned actionable findings. |

The historical result labels reflect the criteria used at the time. The 2026-07-22 explicit control proves named-role plumbing, not automatic selection.

<details><summary>Session evidence</summary>

Gate 1 root: `019f5520-83d8-7543-9b22-8725a27ff31f`. Claude automatic sessions: `d6077efc-68da-477c-8f56-60e5350424be`, `69e7b054-c312-4e55-ac6f-b6b5a6451c66`. Direct inheritance root and child: `019f5529-7d78-7370-8d09-5f51d000617a`, `019f5529-a820-7bc0-b3cc-02e70cc74ede`. Claude control session: `12b9c59b-39c8-4d1f-a35d-d95fa3bd6f7c`. Claude-launched Codex root and child: `019f552b-3cb0-7ac3-a986-bdd07e270b12`, `019f552b-6484-7462-9ed0-fb07eab19151`. Dispatcher smoke roots: `019f5565-760a-7ba3-89c6-c42b9eec0a9b`, `019f5568-86f4-7530-a469-7d5069ba4476`, `019f5568-f540-7c11-98c0-f2d24296f966`, `019f558c-9cd7-72a3-bb1c-f7ec21b4a6ab`, `019f558e-9a6e-73f2-892b-d7a9448b615c`, `019f5591-2734-7df2-9dea-0deae6a7709b`, `019f5595-21dd-7c30-9327-4625105cb417`, and `019f5597-dab1-7553-b929-a5c7af09c324`. Successful exec-backed child: `019f5598-6b8a-7883-9d05-9be34638e736`. Proposal-only roots: `019f559f-f4fa-70f3-a651-8a20538ee9a4` and passing retry `019f55a4-50c3-7820-b4ec-c4dcaf5fc31d`. Passing Stage A V2 root and child: `019f86a9-adf7-7993-bac9-85bca214c8f5`, `019f86aa-040c-7623-a999-1864b08b3f82`. Passing active lookup root and child: `019f8833-33c4-7512-87e1-d2a50620d841`, `019f8833-68a0-73d3-a236-70e542743d11`. Passing neutral automatic review root and child: `019f883f-ff31-7210-ba92-8b89fabc84de`, `019f8840-3ea8-7f42-b650-0f1da029c0c5`.

</details>

## Recent Notes

The former standalone skills repo content now lives under `dots/.claude/` and `dots/.codex/`.

`docs/agent-config.md` defines the local agent-config sync workflow.

`docs/bash.md` defines Bash fast-path behavior and validation.

`repo-agents-md` now captures the workflow for concise repo-specific agent contracts.

Codex uses five action-named GPT-5.6 Sol profiles with pinned effort, Fast speed for lookup only, Standard speed for every other role, explicit sandboxes, and outcome-based stop conditions.

`scripts/fleet-sync.sh` provides a validated network-free preview by default and requires `--apply` before copying explicitly selected files to explicitly selected SSH aliases.

## Validation

For docs-only changes, inspect the Markdown and run a search for stale placeholders, private absolute paths, and old layout names.

For Bash changes, run `bash -n dots/.bashrc dots/.profile` and `shellcheck dots/.bashrc dots/.profile`.

For zsh or tmux changes, validate the affected startup file and make sure the SSH tmux escape hatch remains documented.

For sync changes, run `bash -n scripts/agents-syncs.sh scripts/fleet-sync.sh scripts/tests/sync-scripts.sh`, `shellcheck scripts/agents-syncs.sh scripts/fleet-sync.sh scripts/tests/sync-scripts.sh`, and `scripts/tests/sync-scripts.sh`.
