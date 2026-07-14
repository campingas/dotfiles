# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091
# ~/.bashrc - interactive Bash setup.

# Keep scripts, scp, and cron fast and quiet. Everything below is for humans at
# an interactive prompt.
case $- in
  *i*) ;;
  *) return ;;
esac

# ------------------------------- helpers --------------------------------

_have() { command -v "$1" >/dev/null 2>&1; }
_source_if() { [[ -r "$1" ]] && source "$1"; }

_path_remove() {
  local dir="$1"
  local part new_path old_ifs
  old_ifs=$IFS
  IFS=:
  for part in $PATH; do
    [[ -z "$part" || "$part" == "$dir" ]] && continue
    new_path="${new_path:+$new_path:}$part"
  done
  IFS=$old_ifs
  PATH=$new_path
}

# Tip: these helpers de-duplicate PATH entries before adding them. Put the most
# preferred tools in path_prepend; put compatibility fallbacks in path_append.
path_prepend() {
  local dir i
  local dirs=("$@")
  for ((i = ${#dirs[@]} - 1; i >= 0; i--)); do
    dir=${dirs[i]}
    [[ -d "$dir" ]] || continue
    _path_remove "$dir"
    PATH="$dir${PATH:+:$PATH}"
  done
  export PATH
}

path_append() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] || continue
    _path_remove "$dir"
    PATH="${PATH:+$PATH:}$dir"
  done
  export PATH
}

_source_command() {
  local command_name="$1"
  shift
  _have "$command_name" || return 0
  source <("$command_name" "$@" 2>/dev/null)
}

_agent_shell() {
  [[ "${DOTFILES_AGENT_SHELL:-}" == 0 ]] && return 1
  [[ "${DOTFILES_AGENT_SHELL:-}" == 1 || -n "${CODEX_CI:-}" || -n "${CODEX_SANDBOX:-}" || -n "${CLAUDECODE:-}" ]]
}

# ------------------------------- platform -------------------------------

OS=$(uname -s)
case "$OS" in
  Linux) PLATFORM=linux ;;
  Darwin) PLATFORM=macos ;;
  FreeBSD) PLATFORM=freebsd ;;
  MINGW* | MSYS* | CYGWIN* | *indows*) PLATFORM=windows ;;
  *) PLATFORM=unknown ;;
esac
export OS PLATFORM

# ----------------------------- environment ------------------------------

export USER="${USER:-$(id -un 2>/dev/null || whoami)}"
export REPOS="${REPOS:-$HOME/Repos}"
export GHDIR="${GHDIR:-$REPOS/github.com}"
export GITUSER="${GITUSER:-$USER}"
export GHREPOS="${GHREPOS:-$GHDIR/$GITUSER}"
if [[ -z "${DOTFILES:-}" && -d "$REPOS/dotfiles" ]]; then
  export DOTFILES="$REPOS/dotfiles"
fi

export EDITOR="${EDITOR:-vi}"
export VISUAL="${VISUAL:-$EDITOR}"
export EDITOR_PREFIX="${EDITOR_PREFIX:-$EDITOR}"
export HRULEWIDTH="${HRULEWIDTH:-84}"

export GOBIN="${GOBIN:-$HOME/.local/bin}"
export GOPATH="${GOPATH:-$HOME/.local/share/go}"
export GOPRIVATE="${GOPRIVATE:-github.com/$GITUSER/*,gitlab.com/$GITUSER/*}"

export PNPM_HOME="${PNPM_HOME:-$HOME/.pnpm}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Tip: LC_COLLATE=C gives predictable sort/glob order while keeping UTF-8 input.
export LANG="${LANG:-en_US.UTF-8}"
export LC_COLLATE="${LC_COLLATE:-C}"
export LC_MESSAGES="${LC_MESSAGES:-C}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

export npm_config_yes="${npm_config_yes:-true}"

# -------------------------------- paths ---------------------------------

path_prepend \
  "$HOME/.local/bin" \
  "$HOME/.local/share/mise/shims" \
  "$BUN_INSTALL/bin" \
  "$PNPM_HOME" \
  "$HOME/.cargo/bin"

case "$PLATFORM" in
  macos)
    path_prepend \
      /opt/homebrew/bin \
      /opt/homebrew/sbin \
      /usr/local/bin \
      /usr/local/sbin \
      /opt/homebrew/opt/libpq/bin
    path_append \
      /opt/homebrew/opt/coreutils/libexec/gnubin \
      /usr/local/opt/coreutils/libexec/gnubin
    ;;
  linux)
    path_append \
      /snap/bin \
      "$HOME/.local/share/JetBrains/Toolbox/scripts"
    ;;
  windows)
    path_append /mingw64/bin
    ;;
esac

[[ -n "${DOTFILES:-}" ]] && path_append "$DOTFILES"
[[ -n "${SCRIPTS:-}" ]] && path_prepend "$SCRIPTS"
[[ -n "${NVIM_DIR:-}" ]] && path_prepend "$NVIM_DIR/bin"
[[ -n "${FOUNDRYBIN:-}" ]] && path_prepend "$FOUNDRYBIN"

# ------------------------------- cdpath ---------------------------------

_cdpath_append() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] || continue
    case ":$CDPATH:" in
      *":$dir:"*) ;;
      *) CDPATH="${CDPATH:+$CDPATH:}$dir" ;;
    esac
  done
}

# Tip: CDPATH lets `cd repo-name` work from anywhere. Bash may print the target
# path after cd when CDPATH is used; that is normal.
CDPATH=.
_cdpath_append \
  "$REPOS" \
  "$GHREPOS" \
  "${DOTFILES:-}" \
  "$GHDIR" \
  "/media/$USER" \
  "$HOME"
export CDPATH

# Agents need predictable env and navigation, not prompts or generated
# completions. Set DOTFILES_AGENT_SHELL=0 to force the full interactive setup.
if _agent_shell; then
  export DOTFILES_AGENT_SHELL="${DOTFILES_AGENT_SHELL:-1}"
  return
fi

# ----------------------------- toolchains -------------------------------

# Rust and nvm installers maintain these files. Source them only if present so
# new machines can use the same dotfile before every toolchain is installed.
_source_if "$HOME/.cargo/env"
_source_if "$NVM_DIR/nvm.sh"
_source_if "$NVM_DIR/bash_completion"

# -------------------------------- pager ---------------------------------

if [[ -x /usr/bin/lesspipe ]]; then
  eval "$(SHELL=/bin/sh lesspipe)"
  export LESSOPEN="| /usr/bin/lesspipe %s"
  export LESSCLOSE="/usr/bin/lesspipe %s %s"
fi

# Tip: these colors affect man pages and `git diff | less`, not just `less`.
export LESS_TERMCAP_mb=$'\033[35m'
export LESS_TERMCAP_md=$'\033[33m'
export LESS_TERMCAP_me=
export LESS_TERMCAP_se=
export LESS_TERMCAP_so=$'\033[34m'
export LESS_TERMCAP_ue=
export LESS_TERMCAP_us=$'\033[4m'

export JQ_COLORS="${JQ_COLORS:-38;5;160:38;5;214:38;5;214:38;5;200:38;5;42:38;5;196:38;5;51:38;5;244}"

# ------------------------------- options --------------------------------

set -o vi

shopt -s checkwinsize
shopt -s expand_aliases
shopt -s extglob
shopt -s histappend
shopt -s cdspell 2>/dev/null || true
shopt -s autocd 2>/dev/null || true
shopt -s globstar 2>/dev/null || true

# Tip: Ctrl-S normally freezes terminal output. Disabling XON/XOFF keeps it free
# for editors and fuzzy finders.
[[ -t 0 ]] && stty stop undef 2>/dev/null || true

# ------------------------------- history --------------------------------

# Tip: prefix a command with a space to keep it out of history.
export HISTCONTROL=ignoreboth
export HISTSIZE="${HISTSIZE:-5000}"
export HISTFILESIZE="${HISTFILESIZE:-10000}"

# ------------------------------ keyboard --------------------------------

if _have setxkbmap && [[ -n "${DISPLAY:-}" ]]; then
  setxkbmap -option caps:escape >/dev/null 2>&1
fi

# Ctrl-Up/Down searches history for the current prefix; Ctrl-Left/Right moves by
# words. Most terminals send these escape codes by default.
bind '"\e[1;5A":history-search-backward'
bind '"\e[1;5B":history-search-forward'
bind '"\e[1;5C":forward-word'
bind '"\e[1;5D":backward-word'
bind TAB:menu-complete
bind "set bell-style none"
bind "set show-all-if-ambiguous on"
bind "set menu-complete-display-prefix on"
bind "set show-all-if-unmodified on"
bind "set skip-completed-text off"

# ------------------------------- aliases --------------------------------

# Navigation.
alias ..='cd ..'
alias ...='cd ../..'
alias cdd=cd

# Safer file operations.
alias cp='cp -iv'
alias mv='mv -iv'
alias mkd='mkdir -pv'
alias chmodx='chmod +x'

# Paging and network.
alias lessf='less +F'
alias more='less'
alias wget='wget -c'
alias ping='ping -c 4'

# System info in human units.
alias df='df -H'
alias du='du -ch'

# Misc.
alias clear='printf "\e[H\e[2J"'
alias kl=clear
alias view='vi -R'

case "$PLATFORM" in
  macos | freebsd) alias ls='ls -Gh' ;;
  *) alias ls='ls -h --color=auto' ;;
esac
alias l='ls -l'
alias ll='ls -alF'
alias la='ls -lA'
alias lla='ls -la'
_have lsd && alias ls='lsd'
_have lsd && alias lt='lsd --tree -al'

_have diff && diff --color --version >/dev/null 2>&1 && alias diff='diff --color'
_have free && alias free='free -h'
_have highlight && alias hl='highlight --out-format=ansi'
_have rg && alias rgg='rg -i -M=50'
_have lazygit && alias lzg='lazygit'
_have lazydocker && alias lzd='lazydocker'
_have tmux && alias ktmux='tmux kill-server'
_have ytop && alias ytop='ytop -ps'
_have docker && alias dc='docker compose'
_have podman-compose && alias pc='podman-compose'

# ----------------------------- git helpers ------------------------------

# gpom / gpod push only from expected trunk branches. They are intentionally
# narrow so a quick alias cannot accidentally publish a feature branch.
gpom() {
  local branch_name
  branch_name=$(git branch --show-current)
  if [[ "$branch_name" == "master" || "$branch_name" == "main" ]]; then
    git push origin "$branch_name"
  else
    echo "Not on 'master' or 'main' (currently on '$branch_name')."
  fi
}

gpod() {
  local branch_name
  branch_name=$(git branch --show-current)
  if [[ "$branch_name" == "develop" || "$branch_name" == "dev" ]]; then
    git push origin "$branch_name"
  else
    echo "Not on 'develop' or 'dev' (currently on '$branch_name')."
  fi
}

# ---------------------------- small helpers -----------------------------

# nowat [label] - human-readable timestamp, e.g. `nowat deployed`.
nowat() {
  echo "$1" "$(date "+%A, %B %e, %Y, %l:%M:%S%p")"
}

# epoch - seconds since 1970; call before and after a task to measure elapsed time.
epoch() {
  date +%s
}

myip() {
  local external_ip local_ip

  local_ip=$(ipconfig getifaddr en0 2>/dev/null)
  external_ip=$(dig +short myip.opendns.com @resolver4.opendns.com 2>/dev/null)

  printf 'External: %s\n' "${external_ip:-unavailable}"
  printf 'Local: %s\n' "${local_ip:-unavailable}"
}

# isosec - sortable GMT timestamp (YYYYMMDDHHMMSS), useful for filenames.
isosec() {
  TZ="GMT" date +"%Y%m%d%H%M%S" "$@"
}

rgb() {
  printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"
}

rgbg() {
  printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"
}

# colors - truecolor test strip. A smooth background ramp means 24-bit color is
# passing through; chunky repeated bands usually mean a 256-color downgrade.
# Use `width=40 colors` to print a shorter strip.
colors() {
  awk -v term_cols="${width:-$(tput cols 2>/dev/null || echo 80)}" 'BEGIN{
    s="/\\";
    for (colnum = 0; colnum<term_cols; colnum++) {
      r = 255-(colnum*255/term_cols);
      g = (colnum*510/term_cols);
      b = (colnum*255/term_cols);
      if (g>255) g = 510-g;
      printf "\033[48;2;%d;%d;%dm", r,g,b;
      printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
      printf "%s\033[0m", substr(s,colnum%2+1,1);
    }
    printf "\n";
  }'
}

# dtag [YYYY-MM-DD HH:MM] - Discord timestamp tag for an event in local time.
# Paste the printed <t:...:F> tag into Discord; each reader sees local time.
dtag() {
  local when="$*"
  local date_bin=date
  [[ -z "$when" ]] && read -r -p "Event local time (YYYY-MM-DD HH:MM): " when
  if [[ -z "$when" ]]; then
    echo "usage: dtag YYYY-MM-DD HH:MM" >&2
    return 1
  fi
  if ! date -d "$when" +%s >/dev/null 2>&1; then
    if _have gdate; then
      date_bin=gdate
    else
      echo "dtag needs GNU date; install coreutils for gdate on macOS." >&2
      return 1
    fi
  fi
  local epoch
  epoch=$("$date_bin" -d "$when" +%s) || return 1
  echo "Discord tag for your local time $when - copy this into the chat box:"
  echo "<t:$epoch:F>"
}

# ----------------------------- completion -------------------------------

if shopt -q progcomp; then
  if [[ "$PLATFORM" == "macos" ]]; then
    _source_if /opt/homebrew/etc/profile.d/bash_completion.sh
    _source_if /usr/local/etc/profile.d/bash_completion.sh
  fi

  _cdpath_cd_complete_add() {
    local candidate existing
    candidate="$1"
    for existing in "${COMPREPLY[@]}"; do
      [[ "$existing" == "$candidate" ]] && return
    done
    COMPREPLY+=("$candidate")
  }

  _cdpath_cd_complete() {
    local cur dir candidate base paths
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ "$cur" == */* ]]; then
      while IFS= read -r candidate; do
        _cdpath_cd_complete_add "$candidate"
      done < <(compgen -d -- "$cur")
      return 0
    fi

    while IFS= read -r candidate; do
      _cdpath_cd_complete_add "$candidate"
    done < <(compgen -d -- "$cur")

    IFS=: read -r -a paths <<< "$CDPATH"
    for dir in "${paths[@]}"; do
      [[ -n "$dir" && "$dir" != "." && -d "$dir" ]] || continue
      for candidate in "$dir"/"$cur"*; do
        [[ -d "$candidate" ]] || continue
        base="${candidate##*/}"
        _cdpath_cd_complete_add "$base"
      done
    done
  }

  complete -F _cdpath_cd_complete cd

  _source_command gh completion -s bash
  _source_command pandoc --bash-completion
  _source_command kubectl completion bash
  _have kubectl && _have k && complete -o default -F __start_kubectl k 2>/dev/null || true
  _source_command kind completion bash
  _source_command helm completion bash
  _source_command spotify completion bash
  _source_command forge completions bash
  _source_command cast completions bash
  _source_command anvil completions bash

  _source_if "$HOME/.config/tabtab/bash/__tabtab.bash"
fi

# -------------------------------- prompt --------------------------------

if _have starship; then
  eval "$(starship init bash)"
fi
