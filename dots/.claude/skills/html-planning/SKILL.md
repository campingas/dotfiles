---
name: html-planning
description: Render every non-trivial implementation plan and requested report as a polished standalone HTML page, deliver it locally, and automatically archive it to Plan-Saver with stable project/document identity and append-only versions. Use for "planning-html" or "html-planning", HTML plan/report exports, requested reports or audits, and non-trivial plans in plan mode. Designed for Codex, Claude Code, and other agents that can run Bash skills.
---

# HTML Planning

Render the plan or report as a self-contained HTML file the user can open in Google Chrome, then archive it to Plan-Saver. This is a presentation layer on top of normal work. In plan mode, still submit the normal markdown plan for approval; the HTML never replaces the runtime's approval mechanism.

## Document kinds

- `plan` (default): an implementation plan. Built from [assets/template.html](assets/template.html). Behavior is unchanged from the original skill.
- `report`: a standalone writeup not tied to a plan (analysis, audit, investigation, status report). Built from [assets/template-report.html](assets/template-report.html), which shares the same design system but is shaped as TL;DR, scope and method, numbered findings, analysis, recommendations.

Pick `report` when the user asks for a report, audit, analysis, or writeup of findings. Pick `plan` when the output is steps to implement something.

## Output file

- Path: `<scratchpad>/html-planning-{projectName}-{timestamp}.html`, where `<scratchpad>` is the session scratchpad directory from the system prompt (fall back to `mktemp -d` if there is none). It is session-owned and cleaned up automatically. Never write the file into the user's repo.
- `projectName`: basename of the project directory, lowercased, non-alphanumerics collapsed to `-`.
- `timestamp`: `date +%Y%m%d-%H%M%S`.
- After writing, report the absolute path so the user can open it in Chrome. If a file-delivery tool (SendUserFile) is available, also send the file with `display: "render"`.

## Building the page

Start from the kind's template: read it, then write a copy with the placeholder content replaced by the real content. The template carries the design system (spacing, cards, light/dark, highlight.js wiring); your job is only the content. Keep its structure rather than inventing new CSS, so every document the user opens looks and navigates the same.

The design is an always-dark engineering document. Think internal design doc or well-written RFC, not a marketing page. Content rules:

- Write like an engineer. Dense technical prose with real reasoning, not bullet-fragment filler. Cite files, symbols, PRs, and issues inline as `<code>` or links, such as `infra/src/capsule/ir-executor.ts`, not "the executor file".
- The TL;DR callout is mandatory and comes first: one dense paragraph a reader could stop after. For plans: what's broken or missing, the shape of the fix, key files inline, what is explicitly out of scope. For reports: the question, the headline answer, the strongest evidence, the top recommendation.
- The title carries a small badge for priority/kind (e.g. "P2 · platform protection", "report · security audit"); the subtitle line gives project, date, and provenance (branch, ticket, data range).
- Replace `{{AGENT_NAME}}` with the runtime's human-readable product name: `Codex`, `Claude`, or the actual name used by another agent.
- **At most 2 emoji in the whole document**, and only where one genuinely earns its place. No icon-per-section, no icon-per-step. Section headings are plain bold text.
- Plan steps and report findings are numbered `h3` headings followed by prose and optional code, not boxed cards.
- Code snippets use `<pre><code class="language-xxx">` so highlight.js styles them; HTML-escape snippet content (`<` to `&lt;`, `&` to `&amp;`). Show real code: signatures, diff-shaped parts, commands, evidence excerpts, not filler.
- Plans end with a risks/open-questions section and a verification section; reports end with recommendations, with open questions stating the report's current assumption.
- Highlight.js loads from a CDN; the template's fallback styling keeps code blocks readable offline, so don't inline a highlighter.
- Section titles beyond the mandatory ones are flexible. Use what the document needs, keep the document shape.

## Mandatory Plan-Saver delivery

Archive every HTML plan or report after writing it. The user has explicitly pre-authorized this exact Plan-Saver upload as part of artifact delivery, including during plan mode. Treat it as delivery of the requested document, not implementation of the plan and not a repository mutation.

Run the bundled deterministic uploader instead of recreating `jq` or `curl` commands:

```bash
bash "<skill-directory>/scripts/archive.sh" \
  "$FILE" "$PROJECT" "$SLUG" "$KIND" "$TITLE" "$AGENT"
```

Resolve `<skill-directory>` to the directory containing this `SKILL.md`. Quote every argument. The uploader reads `${PLAN_SAVER_CONFIG}` when set, otherwise `${XDG_CONFIG_HOME:-$HOME/.config}/plan-saver/config.json`; it never prints the token.

Derive the payload fields:

- `project`: same as `projectName` above (repo basename, kebab-cased).
- `slug`: the document title, kebab-cased the same way (lowercase, non-alphanumerics collapsed to `-`, trimmed of leading/trailing `-`). Keep this stable across revisions; never add a timestamp or version to it.
- `kind`: `plan` or `report`.
- `title`: the human-readable document title.
- `agent`: the human-readable runtime name used in the footer, such as `Codex` or `Claude`. Do not use a model name or version.

The uploader returns compact JSON. A success contains `{"archived":true,"url":"...","version":n}`. Report the archive URL and version alongside the local file path. The API automatically appends v2, v3, and later versions for the same `(project, slug, kind)`.

Archival is a completion gate: do not finish the response after creating only the local file. If a higher-priority runtime policy blocks the POST, or config/network/server validation fails, preserve the local file and state `not archived: <reason>` explicitly. Never claim or imply that archival succeeded without the uploader's success JSON.

## When it triggers

- The user says "planning-html" / "html-planning" or asks for a plan as HTML: produce the file even outside plan mode.
- The user asks for an HTML report, audit, or analysis writeup: produce a `report` kind document.
- In plan mode: produce and archive the file immediately before the runtime's plan-approval response, so the HTML and submitted plan say the same thing. A quick throwaway plan ("should I rename this variable?") does not need the ceremony; multi-step implementation plans do.
