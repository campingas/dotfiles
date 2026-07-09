---
name: codex-implementation
description: Delegate a scoped implementation task to the Codex CLI (gpt-5.5), which edits the repo directly, then have Claude inspect the resulting diff and verification. This is how Codex/gpt-5.5 is invoked for implementation work. Use whenever the user asks to hand work off to Codex or GPT, says things like "let codex do it", "have gpt implement this", "delegate this", when the model-selection rubric routes the work to gpt-5.5, or when a bounded task would benefit from a parallel coding agent producing a patch while Claude works on something else. For review-only requests, use the codex-review skill instead.
---

# Codex Implementation

Use Codex as a separate implementation agent for bounded code changes. Claude remains responsible for scoping the task, reviewing the diff, running or checking verification, and explaining the final result.

Do not let Codex commit, push, deploy, or edit global config unless the user explicitly asked for that.

## Preconditions

- `codex exec` refuses to run outside a git repository by default. Don't work around this with `--skip-git-repo-check`; the git baseline is what makes Codex's changes reviewable afterward.
- Implementation runs at high reasoning effort are slow: a trivial add-a-function-with-tests task takes ~40 seconds, so real tasks take minutes to tens of minutes. Never run them under the default Bash timeout: run in the background and monitor, or raise the timeout to the maximum.
- `-o` writes only the agent's **last message** to the report file. This is why the prompt must end with report instructions. That final report is all that gets captured. Full session progress goes to the exec log for diagnostics.

## Workflow

1. Pin the current state: `git status --short`, and snapshot pre-existing modifications with `git diff > "$ARTIFACT_DIR/pre.diff"` so user changes can be distinguished from Codex's afterward.
2. Define the implementation scope: files or behavior to change, files to avoid, constraints, and verification commands.
3. Run `codex exec` with repo write access (command shape below).
4. After Codex exits, read the report, then inspect `git status` and `git diff` against the pre-run snapshot.
5. Run the cheapest reliable verification yourself when practical. Don't take Codex's word that tests passed.
6. Report what Codex changed, what Claude verified, and any remaining risks.

Keep the artifact directory outside the repository. Files dropped inside the repo show up as untracked changes and muddy the diff review.

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-implementation.XXXXXX")"

git diff > "$ARTIFACT_DIR/pre.diff"
# Write a self-contained prompt to $ARTIFACT_DIR/prompt.md, then run:

codex exec \
  -C "$PWD" \
  --add-dir "$ARTIFACT_DIR" \
  -s workspace-write \
  -o "$ARTIFACT_DIR/report.md" \
  - < "$ARTIFACT_DIR/prompt.md" > "$ARTIFACT_DIR/exec.log" 2>&1
```

Use `-s workspace-write` by default. Use `-s danger-full-access` only when the implementation truly needs access outside the repo: app launch automation, simulator work, package manager global state, or other machine-level operations.

## Prompt Requirements

Codex has none of the conversation context, so the prompt must stand alone. Tell Codex:

- The exact implementation goal and acceptance criteria.
- The repo path and current branch context if relevant.
- Which existing patterns, files, or tests to inspect first.
- Files or behavior that must not be changed.
- That it must preserve unrelated user changes.
- That it must not commit, push, deploy, or edit global config.
- Which verification commands to run, or to explain why they were skipped.
- To end with a concise final report (files changed, verification, unresolved questions). This last message is what `-o` captures.

Keep the task bounded. If the requested work bundles several substantial changes, split it into separate Codex runs or ask the user to choose the first scope.

## Example Prompt

```text
You are implementing a scoped change for Claude.

Repository: /absolute/path/to/repo

Goal:
- Add keyboard navigation to the command palette.

Acceptance criteria:
- ArrowUp and ArrowDown move the highlighted item.
- Enter selects the highlighted item.
- Escape closes the palette.
- Existing mouse behavior keeps working.

Constraints:
- Preserve unrelated user changes.
- Do not commit, push, deploy, or edit global config.
- Follow existing component and test patterns.

Verification:
- Run the focused component tests if available.
- Otherwise run the nearest relevant typecheck or test command and explain the choice.

Report:
- Files changed
- Behavioral summary
- Verification run and result
- Anything blocked or uncertain
```

## Review After Codex

Always inspect Codex's diff before telling the user the work is done. Compare against `pre.diff` and revert only Codex-created mistakes when you are sure they are not user changes. If Codex leaves the repo in a worse state or changes unrelated files, stop and report the issue with the diff summary.

If `codex` is not installed or the command fails, report the error (check the exec log) and offer to implement the change directly instead.
