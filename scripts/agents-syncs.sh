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

  sync_skill_tree "$repo_root/dots/.claude/skills" "$HOME/.claude/skills"
  sync_skill_tree "$repo_root/dots/.codex/skills" "$HOME/.codex/skills"
  sync_agent_tree "$repo_root/dots/.codex/agents" "$HOME/.codex/agents"
}

main "$@"
