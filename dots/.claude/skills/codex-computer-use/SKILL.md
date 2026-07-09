---
name: codex-computer-use
description: Ask Codex CLI (gpt-5.5) to run local verification that needs computer use: browser automation, simulators, screenshots, app launching, or independent runtime inspection of a running app. This is how Codex/gpt-5.5 is invoked for computer-use work. Use whenever the user asks Claude to test a flow end-to-end, verify UI behavior, inspect a running app, capture screenshots, click through a page, or confirm implemented behavior actually works at runtime, even if they don't say "computer use". For code review use codex-review; for making code changes use codex-implementation.
---

# Codex Computer Use

Use Codex as a separate local verification agent when the task needs real UI interaction, screenshots, simulator/browser/device state, or an independent runtime check outside Claude's current context.

Do not use this for ordinary code reading, typechecking, linting, or tests Claude can run directly. Launching apps, simulators, or browsers to verify the requested work is fine without asking; ask first only if the run could disrupt the user's environment beyond that (closing their apps, changing system settings, acting on real accounts or data).

## Preconditions

- Under non-interactive `codex exec`, the proven browser backend on this machine is Codex's bundled Playwright skill (`~/.codex/skills/playwright`, headless Chromium via `npx @playwright/cli`). Web checks run headless, opening no visible windows. The `browser`/`chrome` plugins and the Computer Use client in the user's config are desktop-app oriented; don't assume they work in exec mode. Codex also has ordinary shell access to `screencapture`, `osascript`, and `xcrun simctl` for app, system, and simulator work.
- Use `-s danger-full-access` because computer use is machine-level by nature (browsers, TCC-gated screenshots, app control) and the workspace sandbox will block it.
- `codex exec` refuses to run outside a git repository; `-C` into the repo of the app under test. For genuinely repo-less verification, add `--skip-git-repo-check`.
- Anything the app under test needs running (dev server, backend, simulator build) should be started by Claude before the run, and the prompt should say it is already running. Don't make Codex guess how to boot the environment.
- Runs take minutes: UI automation is slower than code review. Run in the background and monitor; never use the default Bash timeout.
- `-o` captures only the agent's last message, so the prompt must end with report instructions.

## Workflow

1. Start whatever the verification target needs (dev server, app build) and confirm it responds.
2. Create the artifact directory outside the repo and write a self-contained prompt that names concrete, observable acceptance checks.
3. Run `codex exec` and wait for it in the background.
4. Read the report, then verify the evidence yourself: open the screenshots with the Read tool and check they show what Codex claims. A screenshot Claude has actually looked at is evidence; a report sentence is not.
5. Report what was verified, with the screenshot paths, and anything Codex flagged as blocked or uncertain.

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-computer-use.XXXXXX")"

# Write a self-contained prompt to $ARTIFACT_DIR/prompt.md, then run:
codex exec \
  -C "$PWD" \
  -s danger-full-access \
  -o "$ARTIFACT_DIR/report.md" \
  - < "$ARTIFACT_DIR/prompt.md" > "$ARTIFACT_DIR/exec.log" 2>&1
```

## Prompt Requirements

Codex has none of the conversation context, so the prompt must stand alone. Tell Codex:

- The exact target (URL, app name, simulator) and that its environment is already running.
- Concrete, observable acceptance checks: element text, states before and after an interaction, expected navigation. Avoid vague "make sure it works" checks.
- The artifact directory path, and which screenshots to save there (one per meaningful state is a good default).
- To interact only with windows/tabs it opened and close them when done; not to touch the user's other apps, accounts, or system settings.
- Not to substitute curl or static HTML reading for real browser interaction, and to say so explicitly if no automation backend is available rather than faking it.
- To end with a report: backend/tools used, observed values, screenshot paths, anything blocked or uncertain.

## Example Prompt

```text
You are running a local UI verification for Claude.

Target: http://localhost:3000/ (dev server already running)
Artifact directory: /tmp/codex-computer-use.XXXXXX

Goal: verify keyboard navigation in the command palette.

Steps:
1. Open the target in a browser you can control.
2. Press Cmd+K and confirm the palette opens.
3. Press ArrowDown twice and confirm the third item is highlighted.
4. Press Enter and confirm the palette closes and the selected view loads.
5. Save screenshots of the opened palette and the final view to the artifact directory.

Constraints:
- Interact only with the tab you opened; close it when done.
- Do not use curl or static analysis as a substitute for real browser interaction.

Report:
- Which browser/automation backend you used
- Observed values at each step
- Screenshot paths
- Anything blocked or uncertain
```

## Review After Codex

Read the screenshots yourself before relaying conclusions. Confirm they show the claimed states, not a blank page or an error. In the user-facing response, separate what Claude verified from what only Codex reported. If Codex says an automation backend was unavailable, report that honestly and fall back to verification Claude can do directly.

If `codex` is not installed or the command fails, report the error (check the exec log) and offer to verify directly instead.
