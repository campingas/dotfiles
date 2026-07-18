# Tasks

This file tracks current dotfiles work so the user and agents can see what changed and what remains open.

## Current Focus

Keep this repo as the single source for shell dotfiles plus coding-agent configuration.

Keep default context small: `AGENTS.md` routes to focused docs instead of carrying full operational detail.

Keep fleet updates confirmation-gated. Agents may prepare a deployment plan, but they must wait for confirmation before copying files to remote machines.

## Open Items

Run `scripts/agents-syncs.sh` after changing managed Claude or Codex instructions, skills, dispatch policy, or Codex subagent profiles.

Complete the two automatic-dispatch validation gates below after a Codex release claims or appears to support named custom agents under `codex exec`.

Validate the exec-backed `codex-dispatch` path after changing its policy, script, skill instructions, or profile files.

Design a fleet-sync helper only after the local dotfile and agent-config sync workflow has settled.

## Automatic Dispatch Validation

Run these gates in order. Use a clean disposable branch or worktree, preserve unrelated changes, and save the Claude transcript, Codex report, exec log, and relevant Codex rollout JSONL files as evidence.

### Test Task

Choose a real approved plan or large bounded task with clear acceptance criteria and at least two independent concerns, such as impact analysis plus implementation, or implementation plus risk review. Keep it large enough that delegation is useful but bounded enough for one final owner.

Use a neutral prompt such as:

```text
Implement the approved plan at <path> end to end. Preserve unrelated changes, follow repository instructions, run the required validation, and stop when the acceptance criteria pass. Report changed files, validation, remaining risk, and intentionally excluded adjacent work.
```

Do not mention Codex, agents, subagents, profile names, models, delegation, fan-out, or parallelism in the prompt. Reusing a task prompt that contains those terms invalidates the test.

### Gate 1: Codex Native Selection

1. Confirm `scripts/agents-syncs.sh` has installed the seven current TOML files under `~/.codex/agents/`, and record the Codex CLI version.
2. Start a fresh Sol-medium Standard-speed root with `codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="medium"' -c 'service_tier="default"' -c 'features.fast_mode=false'` and the neutral test prompt.
3. Let the root plan and execute without steering it toward delegation. Do not send follow-up instructions about agents while it runs.
4. Find the new root and child rollout files under `~/.codex/sessions/`, then inspect every `session_meta` and `turn_context` record.
5. Confirm the root `turn_context` is `gpt-5.6-sol` at `medium` with Standard speed, at least one child `session_meta.payload.source.subagent.thread_spawn.agent_role` equals a managed profile name, and the child's `turn_context` matches that profile's TOML model, effort, speed, and sandbox.
6. Confirm the root waited for the child, integrated its evidence, respected the one-writer rule, and completed the requested validation.

Gate 1 strictly passes only when the named role and configured child runtime are both present in JSONL. A task with no child or explicit user steering toward delegation is a strict failure. An untyped child with `agent_role = null` that matches the root model, effort, speed, and sandbox is recorded separately as an inherited-runtime compatibility pass.

### Gate 2: Claude to Codex Selection

1. Run Gate 2 only after Gate 1 passes, using a fresh Claude Code session on a clean disposable branch or worktree.
2. Confirm the Claude main thread is Fable 5 at medium effort and give it a neutral task of the same qualifying shape without mentioning Codex or delegation.
3. Allow Claude to choose its workflow without steering. Capture the transcript and verify that Claude autonomously invokes the Codex implementation or review workflow and launches `codex exec`.
4. Inspect the resulting Codex root and child rollout JSONL files using the same evidence checks as Gate 1.
5. Confirm at least one Codex child records a managed non-null `agent_role`, its model, effort, speed, and sandbox match the corresponding TOML profile, and Claude reviews and integrates the Codex result before reporting completion.

Gate 2 strictly passes only when Claude autonomously dispatches Codex and the resulting Codex run proves named-profile execution. A Claude-only subagent, a plain Codex root with no child, or a prompt that requested Codex or delegation is a strict failure. If Claude autonomously launches Codex and its untyped child inherits the Codex root model, effort, speed, and sandbox, record a compatibility pass without closing the strict gate.

### Inherited Runtime Control

Run this control separately after the neutral automatic tests. The control explicitly requests one child, so it tests runtime inheritance rather than autonomous dispatch and cannot close Gate 1 or Gate 2.

1. Start a fresh Sol-medium Standard-speed Codex root in read-only mode and explicitly require exactly one child, then verify that a child with `agent_role = null` records the same model, effort, speed, and sandbox in `turn_context`.
2. Start Fable-medium Claude and explicitly require it to launch the same Sol-medium Codex control, then verify the new Codex root and child rollout files independently rather than relying on Claude's summary.
3. Record a compatibility pass only when the child model, effort, speed, and sandbox exactly match the Codex root. A missing child, missing metadata, or a different runtime fails the control.

### Evidence Command

Use the following shape for each candidate rollout file:

```bash
jq -c 'select(.type == "session_meta" or .type == "turn_context") | {type, source: .payload.source, model: .payload.model, effort: .payload.effort, service_tier: .payload.service_tier, sandbox_policy: .payload.sandbox_policy}' <rollout.jsonl>
```

Record the task prompt, CLI versions, root session id, child session ids, selected role names, effective models, efforts, speeds, sandboxes, validation results, and final pass or failure reason in this section after each test.

### Timed Log

All times below are Asia/Ho_Chi_Minh on 2026-07-12. These historical results predate the current all-Sol speed-pinned profile map. The test fixture was disposable, and no test implementation was retained in this repository.

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

Strict pass means automatic named-profile selection. Compat pass proves untyped child inheritance only and does not close either strict gate.

<details><summary>Session evidence</summary>

Gate 1 root: `019f5520-83d8-7543-9b22-8725a27ff31f`. Claude automatic sessions: `d6077efc-68da-477c-8f56-60e5350424be`, `69e7b054-c312-4e55-ac6f-b6b5a6451c66`. Direct inheritance root and child: `019f5529-7d78-7370-8d09-5f51d000617a`, `019f5529-a820-7bc0-b3cc-02e70cc74ede`. Claude control session: `12b9c59b-39c8-4d1f-a35d-d95fa3bd6f7c`. Claude-launched Codex root and child: `019f552b-3cb0-7ac3-a986-bdd07e270b12`, `019f552b-6484-7462-9ed0-fb07eab19151`. Dispatcher smoke roots: `019f5565-760a-7ba3-89c6-c42b9eec0a9b`, `019f5568-86f4-7530-a469-7d5069ba4476`, `019f5568-f540-7c11-98c0-f2d24296f966`, `019f558c-9cd7-72a3-bb1c-f7ec21b4a6ab`, `019f558e-9a6e-73f2-892b-d7a9448b615c`, `019f5591-2734-7df2-9dea-0deae6a7709b`, `019f5595-21dd-7c30-9327-4625105cb417`, and `019f5597-dab1-7553-b929-a5c7af09c324`. Successful exec-backed child: `019f5598-6b8a-7883-9d05-9be34638e736`. Proposal-only roots: `019f559f-f4fa-70f3-a651-8a20538ee9a4` and passing retry `019f55a4-50c3-7820-b4ec-c4dcaf5fc31d`.

</details>

## Recent Notes

The former standalone skills repo content now lives under `dots/.claude/` and `dots/.codex/`.

`docs/agent-config.md` defines the local agent-config sync workflow.

`docs/bash.md` defines Bash fast-path behavior and validation.

`repo-agents-md` now captures the workflow for concise repo-specific agent contracts.

Codex now uses action-named GPT-5.6 Sol profiles with pinned effort and speed, explicit sandboxes, and outcome-based stop conditions.

## Validation

For docs-only changes, inspect the Markdown and run a search for stale placeholders, private absolute paths, and old layout names.

For Bash changes, run `bash -n dots/.bashrc dots/.profile` and `shellcheck dots/.bashrc dots/.profile`.

For zsh or tmux changes, validate the affected startup file and make sure the SSH tmux escape hatch remains documented.

For agent-config changes, run `bash -n scripts/agents-syncs.sh` and `shellcheck scripts/agents-syncs.sh`.
