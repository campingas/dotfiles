#!/usr/bin/env bash
# PreToolUse gate for ExitPlanMode.
#
# Enforces the render half of the html-planning skill: block leaving plan mode
# until an html-planning-*.html artifact exists in this session's scratchpad.
# The skill separately requires Plan-Saver archival before completion; this hook
# cannot verify that remote upload.
#
# Hook contract: exit 0 allows the tool; exit 2 blocks it and feeds stderr back
# to the model as guidance. Any other outcome exits 0 so a broken gate never
# wedges plan mode.
#
# Reports have no deterministic tool trigger, so they are not covered here; they
# rely on the html-planning skill guidance.
set -uo pipefail

input=$(cat)

# Need jq to parse the hook payload; degrade open if it is missing.
command -v jq >/dev/null 2>&1 || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" = "ExitPlanMode" ] || exit 0

session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$session" ] || exit 0

# Look for a recently rendered plan artifact for this session (last 30 min).
found=$(find /private/tmp/claude-* "${TMPDIR:-/tmp}"/claude-* -type f \
  -path "*/$session/scratchpad/html-planning-*.html" -mmin -30 \
  2>/dev/null | head -1 || true)

[ -n "$found" ] && exit 0

cat >&2 <<'MSG'
Blocked: render this plan with the html-planning skill before exiting plan mode.
Invoke the html-planning skill, write the html-planning-*.html file to the session
scratchpad, complete the skill's separate Plan-Saver archive step, then call
ExitPlanMode again. This hook verifies only the session-scoped rendered artifact.
MSG
exit 2
