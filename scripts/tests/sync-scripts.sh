#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sync-tests.XXXXXX")"
fake_home="$test_root/home"

cleanup() {
  [[ -n "$test_root" && -d "$test_root" ]] || return
  rm -rf -- "$test_root"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$fake_home/.claude/skills" "$fake_home/.codex/skills" "$fake_home/.codex/agents" "$test_root/external-skill"
ln -s "$repo_root/dots/.codex/skills/retired-skill" "$fake_home/.codex/skills/retired-skill"
ln -s "$test_root/external-skill" "$fake_home/.codex/skills/external-skill"
ln -s "$repo_root/dots/.codex/agents/retired.toml" "$fake_home/.codex/agents/retired.toml"
printf '%s\n' 'mode = "automatic"' 'backend = "exec"' 'max_parallel = 1' 'capture_evidence = true' 'confirm_profiles = ["implement_deep"]' > "$fake_home/.codex/dispatch.toml"

HOME="$fake_home" "$repo_root/scripts/agents-syncs.sh" > "$test_root/agents-sync.out"

[[ ! -e "$fake_home/.codex/dispatch.toml" ]] || fail "repo-managed legacy dispatch file was not removed"
[[ ! -L "$fake_home/.codex/skills/retired-skill" ]] || fail "stale repo skill link was not pruned"
[[ -L "$fake_home/.codex/skills/external-skill" ]] || fail "external skill link was removed"
[[ ! -L "$fake_home/.codex/agents/retired.toml" ]] || fail "stale repo agent link was not pruned"
[[ "$(find "$fake_home/.codex/agents" -maxdepth 1 -type l | wc -l | tr -d ' ')" == "5" ]] || fail "expected five live agent links"
cmp -s "$repo_root/dots/.claude/CLAUDE.md" "$fake_home/.claude/CLAUDE.md" || fail "Claude policy copy differs"
cmp -s "$repo_root/dots/.codex/AGENTS.md" "$fake_home/.codex/AGENTS.md" || fail "Codex policy copy differs"

printf '%s\n' 'local override' > "$fake_home/.codex/dispatch.toml"
HOME="$fake_home" "$repo_root/scripts/agents-syncs.sh" > "$test_root/agents-sync-second.out" 2> "$test_root/agents-sync-second.err"
[[ "$(<"$fake_home/.codex/dispatch.toml")" == "local override" ]] || fail "modified legacy dispatch file was removed"

fleet_output="$("$repo_root/scripts/fleet-sync.sh" --host example-host --file .zshrc --file tmux.conf)"
[[ "$fleet_output" == *"Preview only. No remote commands will run."* ]] || fail "fleet preview marker missing"
[[ "$fleet_output" == *"destination: ~/.zshrc"* ]] || fail "zsh destination is incorrect"
[[ "$fleet_output" == *"destination: ~/.tmux.conf"* ]] || fail "tmux destination is incorrect"
if "$repo_root/scripts/fleet-sync.sh" --host example-host --file ../outside >/dev/null 2>&1; then
  fail "fleet helper accepted a path outside dots/"
fi

fake_bin="$test_root/bin"
fleet_log="$test_root/fleet.log"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' "printf 'ssh %s\\n' \"\$*\" >> \"\$FLEET_TEST_LOG\"" > "$fake_bin/ssh"
printf '%s\n' '#!/usr/bin/env bash' "printf 'scp %s\\n' \"\$*\" >> \"\$FLEET_TEST_LOG\"" > "$fake_bin/scp"
chmod +x "$fake_bin/ssh" "$fake_bin/scp"
PATH="$fake_bin:$PATH" FLEET_TEST_LOG="$fleet_log" "$repo_root/scripts/fleet-sync.sh" --apply --host example-host --file .zshrc --file tmux.conf > "$test_root/fleet-apply.out"
[[ "$(wc -l < "$fleet_log" | tr -d ' ')" == "4" ]] || fail "fleet apply did not execute two SSH and two SCP commands"
expected_ssh="ssh -- example-host mkdir -p -- \"\$HOME\""
[[ "$(sed -n '1p' "$fleet_log")" == "$expected_ssh" ]] || fail "fleet SSH command differs from previewed behavior"
[[ "$(sed -n '2p' "$fleet_log")" == scp\ --\ "$repo_root/dots/.zshrc"\ example-host:~/.zshrc ]] || fail "fleet SCP command differs from selected zsh copy"

printf 'sync script tests: pass\n'
