#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

copy_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -f "$dst" ]]; then
    printf 'skip non-file destination: %s\n' "$dst" >&2
    return 1
  fi
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    printf 'unchanged %s\n' "$dst"
    return
  fi
  if [[ -f "$dst" ]]; then
    printf 'replace %s\n' "$dst"
    diff -u "$dst" "$src" || true
  else
    printf 'create %s\n' "$dst"
  fi
  cp "$src" "$dst"
}

link_skill() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    printf 'skip existing non-symlink skill: %s\n' "$dst" >&2
    return
  fi
  ln -sfn "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
}

link_agent() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    printf 'skip existing non-symlink agent: %s\n' "$dst" >&2
    return
  fi
  ln -sfn "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
}

prune_claude_html_planning_hook() {
  local settings="$HOME/.claude/settings.json"
  local settings_dir="$HOME/.claude"
  local hook_link="$HOME/.claude/hooks/require-html-planning.sh"
  local hook_target="$repo_root/dots/.claude/hooks/require-html-planning.sh"
  local hook_command='bash ~/.claude/hooks/require-html-planning.sh'
  local status
  local tmp

  if [[ -f "$settings" ]]; then
    command -v jq >/dev/null 2>&1 || {
      printf 'jq is required to remove the retired Claude hook setting\n' >&2
      return 1
    }

    if jq -e --arg command "$hook_command" '
      (.hooks.PreToolUse | type) == "array" and
      any(.hooks.PreToolUse[]?;
        .matcher == "ExitPlanMode" and
        (.hooks | type) == "array" and
        any(.hooks[]?; .type == "command" and .command == $command))
    ' "$settings" >/dev/null; then
      tmp=$(mktemp "$settings_dir/.settings.XXXXXX")
      if ! jq --arg command "$hook_command" '
        .hooks.PreToolUse |= map(
          if .matcher == "ExitPlanMode" then
            .hooks |= map(select(.type != "command" or .command != $command))
          else
            .
          end
        ) |
        .hooks.PreToolUse |= map(select(.matcher != "ExitPlanMode" or (.hooks | length) > 0))
      ' "$settings" > "$tmp"; then
        rm -f "$tmp"
        return 1
      fi
      chmod 600 "$tmp"
      mv -f "$tmp" "$settings"
      printf 'removed retired repo-managed hook setting: %s\n' "$settings"
    else
      status=$?
      if [[ "$status" -ne 1 ]]; then
        printf 'unable to inspect Claude hook settings safely: %s\n' "$settings" >&2
        return 1
      fi
    fi
  fi

  if [[ -L "$hook_link" && "$(readlink "$hook_link")" == "$hook_target" ]]; then
    rm -- "$hook_link"
    printf 'removed retired repo-managed hook link: %s\n' "$hook_link"
  fi
}

prune_repo_skill_links() {
  local skills_src="$1"
  local skills_dst="$2"
  local link target name

  [[ -d "$skills_dst" ]] || return
  for link in "$skills_dst"/*; do
    [[ -L "$link" ]] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$skills_src"/*)
        name="${link##*/}"
        if [[ ! -f "$skills_src/$name/SKILL.md" ]]; then
          rm "$link"
          printf 'pruned stale skill link: %s\n' "$link"
        fi
        ;;
    esac
  done
}

sync_skill_tree() {
  local skills_src="$1"
  local skills_dst="$2"
  local skill

  [[ -d "$skills_src" ]] || return
  mkdir -p "$skills_dst"
  for skill in "$skills_src"/*; do
    [[ -f "$skill/SKILL.md" ]] || continue
    link_skill "$skill" "$skills_dst/${skill##*/}"
  done
  prune_repo_skill_links "$skills_src" "$skills_dst"
}

prune_repo_agent_links() {
  local agents_src="$1"
  local agents_dst="$2"
  local link target name

  [[ -d "$agents_dst" ]] || return
  for link in "$agents_dst"/*.toml; do
    [[ -L "$link" ]] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$agents_src"/*)
        name="${link##*/}"
        if [[ ! -f "$agents_src/$name" ]]; then
          rm "$link"
          printf 'pruned stale agent link: %s\n' "$link"
        fi
        ;;
    esac
  done
}

sync_agent_tree() {
  local agents_src="$1"
  local agents_dst="$2"
  local agent

  [[ -d "$agents_src" ]] || return
  mkdir -p "$agents_dst"
  for agent in "$agents_src"/*.toml; do
    [[ -f "$agent" ]] || continue
    link_agent "$agent" "$agents_dst/${agent##*/}"
  done
  prune_repo_agent_links "$agents_src" "$agents_dst"
}

prune_legacy_dispatch_file() {
  local path="$HOME/.codex/dispatch.toml"
  local expected

  [[ -e "$path" || -L "$path" ]] || return 0
  if [[ -L "$path" || ! -f "$path" ]]; then
    printf 'leave non-regular legacy dispatch path: %s\n' "$path" >&2
    return
  fi

  expected=$'mode = "automatic"\nbackend = "exec"\nmax_parallel = 1\ncapture_evidence = true\nconfirm_profiles = ["implement_deep"]'
  if [[ "$(<"$path")" == "$expected" ]]; then
    rm -- "$path"
    printf 'removed retired repo-managed file: %s\n' "$path"
  else
    printf 'leave modified legacy dispatch file: %s\n' "$path" >&2
  fi
}

main() {
  copy_file "$repo_root/dots/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  copy_file "$repo_root/dots/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  prune_legacy_dispatch_file
  prune_claude_html_planning_hook

  sync_skill_tree "$repo_root/dots/.claude/skills" "$HOME/.claude/skills"
  sync_skill_tree "$repo_root/dots/.codex/skills" "$HOME/.codex/skills"
  sync_agent_tree "$repo_root/dots/.codex/agents" "$HOME/.codex/agents"
}

main "$@"
