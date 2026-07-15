---
name: html-planning
description: Render an implementation plan or a standalone report as a polished standalone HTML page (dark engineering-doc style, syntax-highlighted code, dense technical prose) the user opens in Google Chrome, then silently archive it to the user's plan-saver website. Use whenever the user asks for "planning-html" or "html-planning", asks to render or export a plan as HTML, asks for an HTML report on any topic ("write me an html report on X", "give me a report on the state of Y"), AND whenever presenting a non-trivial implementation plan in plan mode. The user wants their plans as HTML artifacts by default, even without being asked. The HTML complements the normal plan flow; it never replaces plan-approval via ExitPlanMode.
---

# HTML Planning

Render the plan or report you generated as a self-contained HTML file the user can open in Google Chrome. This is a presentation layer on top of normal work. Do the actual planning or research exactly as usual, and in plan mode still submit the markdown plan through ExitPlanMode for approval. The HTML is the human-readable artifact, not the approval mechanism.

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
- **At most 2 emoji in the whole document**, and only where one genuinely earns its place. No icon-per-section, no icon-per-step. Section headings are plain bold text.
- Plan steps and report findings are numbered `h3` headings followed by prose and optional code, not boxed cards.
- Code snippets use `<pre><code class="language-xxx">` so highlight.js styles them; HTML-escape snippet content (`<` to `&lt;`, `&` to `&amp;`). Show real code: signatures, diff-shaped parts, commands, evidence excerpts, not filler.
- Plans end with a risks/open-questions section and a verification section; reports end with recommendations, with open questions stating the report's current assumption.
- Highlight.js loads from a CDN; the template's fallback styling keeps code blocks readable offline, so don't inline a highlighter.
- Section titles beyond the mandatory ones are flexible. Use what the document needs, keep the document shape.

## Archiving to plan-saver

After writing the file (and sending it to the user), upload it to the user's plan-saver archive. This step is silent: missing config, network failure, or a non-2xx response must never block or noisily interrupt the session. The local file remains the source of truth; on failure just note "not archived" next to the local path.

Derive the payload fields:

- `project`: same as `projectName` above (repo basename, kebab-cased).
- `slug`: the document title, kebab-cased the same way (lowercase, non-alphanumerics collapsed to `-`, trimmed of leading/trailing `-`).
- `kind`: `plan` or `report`.
- `title`: the human-readable document title.

Then run (FILE is the HTML path, and the four fields above are shell variables):

```bash
CFG=~/.config/plan-saver/config.json
if [ -f "$CFG" ]; then
  jq -n --arg project "$PROJECT" --arg slug "$SLUG" --arg kind "$KIND" --arg title "$TITLE" \
        --rawfile html "$FILE" \
        --arg branch "$(git branch --show-current 2>/dev/null || true)" \
        --arg repoPath "$PWD" --arg hostname "$(hostname)" \
        '{project:$project, slug:$slug, kind:$kind, title:$title, html:$html,
          meta:{branch:$branch, repoPath:$repoPath, generator:"html-planning@2", hostname:$hostname}}' \
  | curl -sS --fail-with-body -m 30 -X POST "$(jq -r .url "$CFG")/api/v1/documents" \
      -H "Authorization: Bearer $(jq -r .token "$CFG")" \
      -H "Content-Type: application/json" --data-binary @- \
  || echo "plan-saver: not archived"
fi
```

A success returns `{"url": "...", "version": n}`. Report that archive URL and version alongside the local file path. Re-generating a document with the same title in the same project intentionally chains v2, v3, and so on under one document.

## When it triggers

- The user says "planning-html" / "html-planning" or asks for a plan as HTML: produce the file even outside plan mode.
- The user asks for an HTML report, audit, or analysis writeup: produce a `report` kind document.
- In plan mode: produce the file right before calling ExitPlanMode, so the HTML and the submitted plan say the same thing. A quick throwaway plan ("should I rename this variable?") doesn't need the ceremony; use judgment. Multi-step implementation plans do.
