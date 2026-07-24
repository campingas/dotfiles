#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
apply=0
hosts=()
files=()

usage() {
  cat <<'EOF'
Usage: scripts/fleet-sync.sh --host SSH_ALIAS --file DOTS_PATH [options]

Preview selected files from dots/ to the same paths below a remote home.
Repeat --host and --file as needed. Pass --apply only after reviewing the
complete preview.

Options:
  --host SSH_ALIAS  Existing SSH alias or explicit SSH host.
  --file DOTS_PATH  File path relative to dots/.
  --apply           Execute the displayed SSH and SCP commands.
  -h, --help        Show this help.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_value() {
  local option="$1"
  local value="${2:-}"

  [[ -n "$value" ]] || die "$option requires a value"
}

validate_host() {
  local host="$1"

  [[ "$host" =~ ^[A-Za-z0-9._@-]+$ ]] || die "unsafe SSH host: $host"
  [[ "$host" != -* ]] || die "SSH host cannot begin with '-': $host"
}

validate_relative_path() {
  local path="$1"

  [[ "$path" =~ ^[A-Za-z0-9._/-]+$ ]] || die "unsafe dots path: $path"
  [[ "$path" != /* && "$path" != */../* && "$path" != ../* && "$path" != */.. && "$path" != .. ]] || die "dots path must stay below dots/: $path"
  [[ "$path" != *//* ]] || die "dots path contains an empty component: $path"
}

show_or_apply() {
  local host="$1"
  local relative="$2"
  local source destination parent remote_dir remote_command remote_target

  source="$repo_root/dots/$relative"
  [[ -f "$source" ]] || die "missing dots file: $relative"
  destination="$relative"
  parent="$(dirname "$destination")"
  remote_dir="\$HOME"
  [[ "$parent" == "." ]] || remote_dir="\$HOME/$parent"
  remote_command="mkdir -p -- \"$remote_dir\""
  remote_target="$host:~/$destination"

  printf 'host: %s\n' "$host"
  printf 'source: %s\n' "$source"
  printf 'destination: ~/%s\n' "$destination"
  printf 'commands:\n'
  printf '  ssh -- %q %q\n' "$host" "$remote_command"
  printf '  scp -- %q %q\n' "$source" "$remote_target"

  if ((apply == 0)); then
    return
  fi
  ssh -- "$host" "$remote_command"
  scp -- "$source" "$remote_target"
}

main() {
  local host relative

  while (($#)); do
    case "$1" in
      --host)
        require_value "$1" "${2:-}"
        hosts+=("$2")
        shift 2
        ;;
      --file)
        require_value "$1" "${2:-}"
        files+=("$2")
        shift 2
        ;;
      --apply)
        apply=1
        shift
        ;;
      -h | --help)
        usage
        return
        ;;
      *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
  done

  ((${#hosts[@]} > 0)) || die "at least one --host is required"
  ((${#files[@]} > 0)) || die "at least one --file is required"

  for host in "${hosts[@]}"; do
    validate_host "$host"
  done
  for relative in "${files[@]}"; do
    validate_relative_path "$relative"
    [[ -f "$repo_root/dots/$relative" ]] || die "missing dots file: $relative"
  done

  if ((apply == 0)); then
    printf 'Preview only. No remote commands will run.\n'
  else
    printf 'Applying explicitly confirmed fleet copy.\n'
  fi

  for host in "${hosts[@]}"; do
    for relative in "${files[@]}"; do
      show_or_apply "$host" "$relative"
    done
  done

  if ((apply == 0)); then
    printf 'Review every host and destination, then rerun with --apply.\n'
  else
    printf 'Fleet copy complete.\n'
  fi
}

main "$@"
