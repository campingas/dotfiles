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

link_hook() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    printf 'skip existing non-symlink hook: %s\n' "$dst" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
}

ensure_claude_html_planning_hook() {
  local settings="$HOME/.claude/settings.json"
  local settings_dir="$HOME/.claude"
  local hook_command='bash ~/.claude/hooks/require-html-planning.sh'
  local tmp

  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required to merge Claude hook settings\n' >&2
    return 1
  }
  mkdir -p "$settings_dir"

  if [[ -f "$settings" ]] && jq -e --arg command "$hook_command" '
    any(.hooks.PreToolUse[]?;
      .matcher == "ExitPlanMode" and
      any(.hooks[]?; .type == "command" and .command == $command))
  ' "$settings" >/dev/null; then
    printf 'unchanged %s\n' "$settings"
    return
  fi

  tmp=$(mktemp "$settings_dir/.settings.XXXXXX")
  if [[ -f "$settings" ]]; then
    if ! jq --arg command "$hook_command" '
      .hooks //= {} |
      .hooks.PreToolUse //= [] |
      if any(.hooks.PreToolUse[]?; .matcher == "ExitPlanMode") then
        .hooks.PreToolUse |= map(
          if .matcher == "ExitPlanMode" then
            .hooks += [{"type":"command", "command":$command}]
          else . end
        )
      else
        .hooks.PreToolUse += [{
          "matcher":"ExitPlanMode",
          "hooks":[{"type":"command", "command":$command}]
        }]
      end
    ' "$settings" > "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
  else
    jq -n --arg command "$hook_command" '{
      hooks:{PreToolUse:[{
        matcher:"ExitPlanMode",
        hooks:[{type:"command", command:$command}]
      }]}
    }' > "$tmp"
  fi
  chmod 600 "$tmp"
  mv -f "$tmp" "$settings"
  printf 'updated %s\n' "$settings"
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
        if [[ ! -d "$skills_src/$name" ]]; then
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
    [[ -d "$skill" ]] || continue
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

main() {
  copy_file "$repo_root/dots/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  copy_file "$repo_root/dots/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  copy_file "$repo_root/dots/.codex/dispatch.toml" "$HOME/.codex/dispatch.toml"
  link_hook "$repo_root/dots/.claude/hooks/require-html-planning.sh" "$HOME/.claude/hooks/require-html-planning.sh"
  ensure_claude_html_planning_hook

  sync_skill_tree "$repo_root/dots/.claude/skills" "$HOME/.claude/skills"
  sync_skill_tree "$repo_root/dots/.codex/skills" "$HOME/.codex/skills"
  sync_agent_tree "$repo_root/dots/.codex/agents" "$HOME/.codex/agents"
}

main "$@"
