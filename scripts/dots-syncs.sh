#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
apply=0
changes=0
backup_dir=""

usage() {
  cat <<'EOF'
Usage: scripts/dots-syncs.sh [--apply]

Preview links from dots/ into the current user's home directory by default.
Pass --apply only after reviewing the preview. Existing destinations are moved
to a timestamped backup before links are created.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

destination_has_symlink_parent() {
  local path parent
  path="$1"
  parent="$(dirname "$path")"

  while [[ "$parent" != "$HOME" && "$parent" != / && "$parent" != . ]]; do
    [[ -L "$parent" ]] && return 0
    parent="$(dirname "$parent")"
  done
  return 1
}

ensure_backup_dir() {
  [[ -n "$backup_dir" ]] && return
  backup_dir="$HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p "$backup_dir"
}

backup_destination() {
  local dst relative backup
  dst="$1"
  relative="${dst#"$HOME"/}"
  [[ "$relative" != "$dst" ]] || die "destination is outside HOME: $dst"

  ensure_backup_dir
  backup="$backup_dir/$relative"
  mkdir -p "$(dirname "$backup")"
  mv -- "$dst" "$backup"
  printf 'backed up %s -> %s\n' "$dst" "$backup"
}

link_file() {
  local src dst state
  src="$1"
  dst="$2"

  [[ -f "$src" ]] || die "missing source file: $src"

  if destination_has_symlink_parent "$dst"; then
    printf 'skip destination below a symlinked directory: %s\n' "$dst" >&2
    return 1
  fi

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    printf 'unchanged %s -> %s\n' "$dst" "$src"
    return
  fi

  state=missing
  if [[ -L "$dst" ]]; then
    state="different symlink"
  elif [[ -e "$dst" ]]; then
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      state="identical file"
    else
      state="different destination"
    fi
  fi

  changes=$((changes + 1))
  if ((apply == 0)); then
    printf 'would link %s -> %s (%s)\n' "$dst" "$src" "$state"
    if [[ "$state" == "different destination" && -f "$dst" ]]; then
      diff -u "$dst" "$src" || true
    fi
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup_destination "$dst"
  fi
  ln -s "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
}

remove_retired_symlink() {
  local dst retired_target
  dst="$1"
  retired_target="$2"

  [[ -L "$dst" ]] || return 0
  [[ "$(readlink "$dst")" == "$retired_target" ]] || return 0

  if destination_has_symlink_parent "$dst"; then
    printf 'skip retired symlink below a symlinked directory: %s\n' "$dst" >&2
    return
  fi

  changes=$((changes + 1))
  if ((apply == 0)); then
    printf 'would remove retired symlink %s -> %s\n' "$dst" "$retired_target"
    return
  fi

  rm -- "$dst"
  printf 'removed retired symlink %s -> %s\n' "$dst" "$retired_target"
}

remove_retired_links() {
  remove_retired_symlink "$HOME/.tmux.conf" "$repo_root/dots/tmux.conf"
  remove_retired_symlink "$HOME/.config/cmux/cmux.json" "$repo_root/dots/.config/cmux/cmux.json"
}

sync_home_files() {
  link_file "$repo_root/dots/.bashrc" "$HOME/.bashrc"
  link_file "$repo_root/dots/.inputrc" "$HOME/.inputrc"
  link_file "$repo_root/dots/.profile" "$HOME/.profile"
  link_file "$repo_root/dots/.vimrc" "$HOME/.vimrc"
  link_file "$repo_root/dots/.zshrc" "$HOME/.zshrc"
}

sync_config_files() {
  local config_root src relative
  config_root="$repo_root/dots/.config"
  [[ -d "$config_root" ]] || return

  while IFS= read -r -d '' src; do
    relative="${src#"$config_root"/}"
    link_file "$src" "$HOME/.config/$relative"
  done < <(find "$config_root" -type f -print0)
}

main() {
  case "${1:-}" in
    "") ;;
    --apply) apply=1 ;;
    -h | --help)
      usage
      return
      ;;
    *)
      usage >&2
      die "unknown argument: $1"
      ;;
  esac
  (($# <= 1)) || die "expected at most one argument"

  [[ -d "$HOME" ]] || die "HOME does not exist: $HOME"

  if ((apply)); then
    printf 'Applying dotfile links from %s\n' "$repo_root/dots"
  else
    printf 'Previewing dotfile links from %s\n' "$repo_root/dots"
  fi

  remove_retired_links
  sync_home_files
  sync_config_files

  if ((apply)); then
    printf 'Apply complete: %d link change(s).\n' "$changes"
    [[ -z "$backup_dir" ]] || printf 'Backups: %s\n' "$backup_dir"
  else
    printf 'Preview complete: %d link change(s).\n' "$changes"
    ((changes == 0)) || printf 'Review the output, then rerun with --apply.\n'
  fi
}

main "$@"
