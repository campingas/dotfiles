# Agent Config

This repo tracks the user's global coding-agent configuration under `dots/`.

## Layout

`dots/.claude/CLAUDE.md` is the source for `~/.claude/CLAUDE.md`.

`dots/.claude/skills/` contains repo-authored Claude skills.

`dots/.codex/AGENTS.md` is the source for `~/.codex/AGENTS.md`.

`dots/.codex/skills/` contains repo-authored Codex skills.

`dots/.codex/agents/` contains repo-authored Codex subagent profiles.

Root `AGENTS.md` is the repo-local routing contract for agents working in this checkout, and should not duplicate global defaults.

Root `CLAUDE.md` is a thin adapter that points Claude at root `AGENTS.md`.

## Sync

Run `scripts/agents-syncs.sh` after editing Claude config, Codex config, or repo-authored skills.

The script copies global adapter files into `~/.claude/` and `~/.codex/`.

The script symlinks each directory under `dots/.claude/skills/` into `~/.claude/skills/`.

The script symlinks each directory under `dots/.codex/skills/` into `~/.codex/skills/`.

The script symlinks each TOML file under `dots/.codex/agents/` into `~/.codex/agents/`.

The script prunes only stale skill symlinks that point back into this repo.

Skills that already exist in live skill directories but do not point into this repo are left untouched.

Agent profiles that already exist in the live agent directory but do not point into this repo are left untouched.

## Subagent Dispatch

Codex delegates selectively when a bounded independent task benefits from parallel work or context isolation. It uses at most three children concurrently and only one writing agent.

Reasoning effort defaults to `high`. Only the `scout` profile uses `medium`, for work that is obviously straightforward, low-risk, and tightly scoped. No managed profile may use another effort level.

Use `scout` with GPT-5.6 Luna for simple discovery, `explorer` with GPT-5.6 Terra for substantial read-only analysis, `worker` with Terra for normal implementation, and `expert_worker` or `reviewer` with GPT-5.6 Sol for demanding changes and review.

`compat_worker` uses GPT-5.5 when a preferred GPT-5.6 implementation profile is unavailable. `compat_reviewer` uses GPT-5.6 Luna at high effort when the Sol reviewer is unavailable. Models outside this managed portfolio must not be selected.

## Public Repo Safety

Do not duplicate machine inventory, LAN details, serials, or private operational notes here.

Refer to the local hardware inventory repo generically when hardware context is needed.

Keep global agent instructions concise and public-safe.

Use the Codex `repo-agents-md` skill when creating or refreshing repo-local `AGENTS.md` files.
