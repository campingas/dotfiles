---
name: codex-review
description: Get an independent code review from the Codex CLI (GPT) on uncommitted changes, a branch diff, a single commit, or a specific implementation. This is how Codex/GPT is invoked for review work. Use whenever the user asks to have Codex or GPT review something, wants a second opinion or second pass on a change, says things like "double-check my work", "ask codex", "have another model look at this", or when a change is broad or risky enough that an outside perspective is worth it before shipping. For a review by Claude itself, use the normal review process instead.
---

# Codex Review

Use Codex as an independent reviewer when the user wants a second-pass review or when a change is broad enough that another agent's perspective is useful.

Prefer Claude's normal review process for small local checks. Do not delegate review just to avoid reading the code yourself. Treat Codex's output as evidence, not authority.

## Preconditions

- `codex review` diffs against git state in all modes, so the target must be a git repository. If it isn't, say so and offer a direct review instead.
- Reviews run at high reasoning effort and are slow: a trivial 9-line diff takes ~40 seconds, so real diffs take minutes. Never run them under the default Bash timeout; raise the timeout to the maximum or run in the background and poll. Killing Codex mid-review is the most common failure mode.
- The report is written to stdout; all progress/session noise goes to stderr. Keep them separated as below, and check stderr when diagnosing a failure. Findings cite `file:line` with priority labels like [P1]/[P2].

## Workflow

1. Identify the review target: uncommitted changes, base branch, commit SHA, PR checkout, or specific files.
2. Create a temporary artifact directory and write the review prompt into a file there.
3. Run `codex review` with the prompt on stdin, capturing stdout (the report) separately from stderr (progress noise).
4. Read Codex's report and verify important claims against the code before presenting them.

Codex has two mutually exclusive review modes. The scope flags (`--uncommitted`, `--base`, `--commit`) cannot be combined with a custom prompt. Choose per task:

- **Scope flag, built-in prompt**: when a standard bug-hunting review of a well-defined diff is all that's needed.
- **Custom prompt, no scope flag**: when the review needs task context (requirements, risky areas, expected behavior) or a non-default target. State the review target explicitly in the prompt text.

Keep the artifact directory outside the repository (as below). Prompt or report files dropped inside the repo show up as untracked changes and Codex will review its own artifacts.

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REPORT="$ARTIFACT_DIR/report.md"
PROMPT="$ARTIFACT_DIR/prompt.md"

# Mode A: scoped diff with Codex's built-in review prompt. Pick ONE:
codex -C "$PWD" review --uncommitted > "$REPORT" 2> "$ARTIFACT_DIR/stderr.log"   # staged + unstaged + untracked
codex -C "$PWD" review --base main   > "$REPORT" 2> "$ARTIFACT_DIR/stderr.log"   # branch vs base
codex -C "$PWD" review --commit <sha> > "$REPORT" 2> "$ARTIFACT_DIR/stderr.log"  # one commit

# Mode B: custom review instructions (prompt must name the target itself).
cat > "$PROMPT" <<'EOF'
Review the uncommitted changes in this repository for bugs, regressions, missing tests, security issues, and requirement mismatches.

Prioritize findings over summary. For each finding include:
- severity
- file and line reference
- concrete failure mode
- suggested fix direction

Do not edit files. If there are no substantive findings, say so and name any residual test gaps.
EOF
codex -C "$PWD" review - < "$PROMPT" > "$REPORT" 2> "$ARTIFACT_DIR/stderr.log"
```

In Mode B, append task-specific context to the prompt: requirements, risky areas, expected behavior, relevant tests, or files Claude is unsure about. Codex only sees the diff and the repo. It has none of the conversation context, so anything it needs to judge "does this match what was asked" must be in the prompt.

## Reporting Back

Before relaying a Codex finding, inspect the cited code or diff enough to decide whether the finding is real. In the user-facing response, separate confirmed issues from Codex suggestions you did not verify.

If Codex finds nothing, say that clearly and mention what review target it inspected.

If `codex` is not installed or the command fails, report the error (check the stderr log) and offer to review the changes directly instead.
