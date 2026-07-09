---
name: repo-agents-md
description: Create or update a repository-specific AGENTS.md. Use when the user asks to generate, refresh, optimize, review, or make token-efficient repo instructions, agent guidance, repository routing docs, or AGENTS.md content for a new or existing repo.
---

# Repo AGENTS.md

Create a compact repo-specific `AGENTS.md` that helps agents find the right context fast.

## Workflow

1. Read the existing `AGENTS.md` if present.
2. Read the global or parent agent contract if it is available in the task context.
3. Inspect repo truth before writing: `README*`, docs index, package manifests, task runners, test config, deployment scripts, and current git status.
4. Identify which instructions are global and which are truly repo-specific.
5. Write or update `AGENTS.md` as a router, not a full manual.
6. Move durable detail into focused docs when the repo needs more than a short routing contract.

## What To Keep In AGENTS.md

Keep only guidance that changes agent behavior in this repo.

Include:

- repo purpose in one short paragraph
- where to read first by task type
- repo-specific build, test, deploy, or sync commands
- repo-specific safety boundaries, such as confirmation before remote changes
- package manager exceptions only when they differ from the global contract
- commit and push policy only when it differs from the global contract or the repo must be standalone

Omit:

- generic coding style already covered globally
- long architecture explanations
- long command catalogs
- historical changelog entries
- duplicated secrets, host inventories, LAN details, or private machine paths

## Token Efficiency Rules

Prefer 30-80 lines.

Use short sections and single-line paragraphs.

Route optional detail to files such as `docs/README.md`, `docs/tasks.md`, `docs/current-state.md`, `docs/testing.md`, or domain-specific docs.

Name exact files to read only when that materially saves exploration.

Do not front-load every possible command; list the normal validation command and route deeper workflows.

If global instructions are known, do not repeat them unless the repo may be consumed without that global context.

## Update Existing Files

Preserve useful repo-specific guidance from the old file.

Delete stale placeholders and old layout references.

When adding a routed doc, update the docs index and current-state/task docs if the repo uses them.

Keep Markdown public-safe: no private absolute home paths, no secrets, and no duplicated machine inventory.

## Validation

Run a stale-reference scan over changed docs for placeholders, private paths, and old layout names.

Run syntax or task-runner checks only when the instruction change references those workflows.

Report what was optimized, what moved to routed docs, and any assumptions.
