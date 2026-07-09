---
name: html-planning
description: Render an implementation plan as a polished standalone HTML page (dark engineering-doc style, syntax-highlighted code, dense technical prose) the user opens in Google Chrome. Use whenever the user asks for "planning-html" or "html-planning", asks to render or export a plan as HTML, AND whenever presenting a non-trivial implementation plan in plan mode. The user wants their plans as HTML artifacts by default, even without being asked. The HTML complements the normal plan flow; it never replaces plan-approval via ExitPlanMode.
---

# HTML Planning

Render the plan you generated as a self-contained HTML file the user can open in Google Chrome. This is a presentation layer on top of normal planning. Do the actual planning work (exploring the code, weighing approaches) exactly as usual, and in plan mode still submit the markdown plan through ExitPlanMode for approval. The HTML is the human-readable artifact, not the approval mechanism.

## Output file

- Path: `<scratchpad>/html-planning-{projectName}-{timestamp}.html`, where `<scratchpad>` is the session scratchpad directory from the system prompt (fall back to `mktemp -d` if there is none). It is session-owned and cleaned up automatically. Never write the file into the user's repo.
- `projectName`: basename of the project directory, lowercased, non-alphanumerics collapsed to `-`.
- `timestamp`: `date +%Y%m%d-%H%M%S`.
- After writing, report the absolute path so the user can open it in Chrome. If a file-delivery tool (SendUserFile) is available, also send the file with `display: "render"`.

## Building the page

Start from [assets/template.html](assets/template.html): read it, then write a copy with the placeholder content replaced by the real plan. The template carries the design system (spacing, cards, light/dark, highlight.js wiring); your job is only the content. Keep its structure rather than inventing new CSS, so every plan the user opens looks and navigates the same.

The design is an always-dark engineering document. Think internal design doc or well-written RFC, not a marketing page. Content rules:

- Write like an engineer. Dense technical prose with real reasoning, not bullet-fragment filler. Cite files, symbols, PRs, and issues inline as `<code>` or links, such as `infra/src/capsule/ir-executor.ts`, not "the executor file".
- The TL;DR callout is mandatory and comes first: one dense paragraph a reader could stop after. Include what's broken or missing, the shape of the fix, key files inline, and what is explicitly out of scope.
- The title carries a small badge for priority/kind (e.g. "P2 · platform protection"); the subtitle line gives project, date, and provenance (branch, ticket, replaced PRs).
- **At most 2 emoji in the whole document**, and only where one genuinely earns its place. No icon-per-section, no icon-per-step. Section headings are plain bold text.
- Steps are numbered `h3` headings ("1. Add the meter: `src/meter.ts`") followed by prose and optional code, not boxed cards.
- Code snippets use `<pre><code class="language-xxx">` so highlight.js styles them; HTML-escape snippet content (`<` to `&lt;`, `&` to `&amp;`). Show real code from the plan: signatures, diff-shaped parts, commands, not filler.
- Risks and open questions get their own section; bold-lead bullets ("**Risk lead**: consequence and mitigation"), with open questions stating the plan's current assumption.
- Highlight.js loads from a CDN; the template's fallback styling keeps code blocks readable offline, so don't inline a highlighter.
- Section titles beyond TL;DR/Implementation/Risks/Verification are flexible. Use what the plan needs ("Inspired by", "Current state", "Design"), keep the document shape.

## When it triggers

- The user says "planning-html" / "html-planning" or asks for a plan as HTML: produce the file even outside plan mode.
- In plan mode: produce the file right before calling ExitPlanMode, so the HTML and the submitted plan say the same thing. A quick throwaway plan ("should I rename this variable?") doesn't need the ceremony; use judgment. Multi-step implementation plans do.
