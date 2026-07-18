# ~/.zshrc - interactive shell setup for robrog (Ubuntu).

# Stop early for scripts, scp, cron, and other non-interactive shells.
[[ -o interactive ]] || return

# -------------------------------- tmux --------------------------------
# SSH sessions attach to a durable tmux session so work survives disconnects.
# Escape hatch: `NO_TMUX=1 ssh linpc` for a plain shell.
if [[ -n "$SSH_TTY" && -z "$TMUX" && -z "$NO_TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s rob
fi

# ------------------------------- helpers ------------------------------
path_prepend() {
  [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

has() {
  (( $+commands[$1] ))
}

# ----------------------------- environment ----------------------------
export USER="${USER:-$(id -un 2>/dev/null || whoami)}"
export REPOS="${REPOS:-$HOME/Repos}"
export GHDIR="${GHDIR:-$REPOS/github.com}"
export GITUSER="${GITUSER:-$USER}"

if [[ -z "${GHREPOS:-}" ]]; then
  if [[ -d "$GHDIR/$GITUSER" ]]; then
    export GHREPOS="$GHDIR/$GITUSER"
  else
    for owner_dir in "$GHDIR"/*(N/); do
      [[ -d "$owner_dir" ]] || continue
      export GHREPOS="$owner_dir"
      break
    done
    export GHREPOS="${GHREPOS:-$GHDIR/$GITUSER}"
  fi
fi

if [[ -z "${DOTFILES:-}" && -d "$REPOS/dotfiles" ]]; then
  export DOTFILES="$REPOS/dotfiles"
fi

# ------------------------------- paths --------------------------------
path_prepend "$HOME/.local/bin"
if [[ -d /opt/homebrew ]]; then
  path_prepend /opt/homebrew/bin
  path_prepend /opt/homebrew/sbin
fi

# Node is managed by mise. Bun is installed with the official Bun installer.
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
elif has mise; then
  eval "$(mise activate zsh)"
fi

export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"

# Rust is installed with the official rustup installer.
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ------------------------------ editor --------------------------------
export EDITOR=vim
export VISUAL=vim

# ------------------------------- options ------------------------------
setopt auto_cd
setopt interactive_comments
setopt no_beep
setopt numeric_glob_sort

# Vim keybindings for the shell line editor.
bindkey -v
# Keep Esc fast for Vim mode, but leave enough room for Alt/Meta keys over SSH.
KEYTIMEOUT=10

# ------------------------------- history ------------------------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_expire_dups_first
setopt hist_find_no_dups

# ------------------------------- cdpath -------------------------------
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

_cdpath_append_children() {
  local parent dir

  for parent in "$@"; do
    [[ -d "$parent" ]] || continue
    for dir in "$parent"/*(N/); do
      _cdpath_append "$dir"
    done
  done
}

# Lets `cd repo-name` work from anywhere, plus direct cd into directories one
# level inside each repo under ~/Repos/github.com/$GITUSER.
CDPATH=.
_cdpath_append \
  "$REPOS" \
  "$GHREPOS" \
  "${DOTFILES:-}" \
  "$GHDIR" \
  "/media/$USER" \
  "$HOME"
_cdpath_append_children "$GHREPOS"
export CDPATH

# ------------------------------ completion ----------------------------
autoload -Uz compinit
_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ "$_compdump" -nt "$HOME/.zshrc" ]]; then
  compinit -C -d "$_compdump"
else
  compinit -d "$_compdump"
fi
unset _compdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*:cd:*' tag-order local-directories path-directories

# ------------------------------- aliases ------------------------------
# Directory listings.
if has lsd; then
  alias ls='lsd'
  alias l='ls -l'
  alias ll='ls -alF'
  alias la='ls -lA'
  alias lla='ls -la'
  alias lt='ls --tree'
else
  alias ls='ls --color=auto'
  alias l='ls -l'
  alias ll='ls -alF'
  alias la='ls -lA'
  alias lla='ls -la'
fi

# File operations.
alias cp='cp -iv'
alias mv='mv -iv'
alias mkd='mkdir -pv'
alias chmodx='chmod +x'

# Paging, search, and network.
alias more='less'
alias lessf='less +F'
alias wget='wget -c'
alias ping='ping -c 4'
has rg && alias grep='rg --color=auto'

# System info in human units.
alias diff='diff --color=auto'
alias free='free -h'
alias df='df -H'
alias du='du -ch'

# Common tools.
alias vi='vim'
alias dc='docker compose'
alias clear='printf "\e[H\e[2J"'
alias kl=clear
alias temp='cd "$(mktemp -d -t zsh.XXXXX)"'

# Ubuntu package fallbacks.
has fdfind && ! has fd && alias fd='fdfind'
has batcat && ! has bat && alias bat='batcat'

# ------------------------------- zoxide -------------------------------
if has zoxide; then
  eval "$(zoxide init zsh)"
fi

# -------------------------------- fzf ---------------------------------
if has fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
elif has fdfind; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --strip-cwd-prefix'
fi

if [[ -n "$FZF_DEFAULT_COMMAND" ]]; then
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if has fzf-tmux; then
  export FZF_TMUX_OPTS='-p 80%,70%'
fi

export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

if has bat; then
  export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
elif has batcat; then
  export _FZF_PREVIEW_CMD='batcat --color=always --style=plain,numbers --line-range=:500 {}'
else
  export _FZF_PREVIEW_CMD='sed -n "1,200p" {}'
fi

export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

if has fzf && fzf --help 2>/dev/null | command grep -q -- '--zsh'; then
  source <(fzf --zsh) 2>/dev/null
else
  # Ubuntu fzf integration.
  [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
  [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null

  # Homebrew fallback for local macOS shells.
  [[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh 2>/dev/null
  [[ -r /opt/homebrew/opt/fzf/shell/completion.zsh ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null
fi

_fzf_file_no_hidden() {
  local cmd result
  local fzf_cmd=(fzf)

  [[ -z "$FZF_DEFAULT_COMMAND" ]] && return 1
  [[ -n "${TMUX_PANE:-}" && -n "${FZF_TMUX_OPTS:-}" && ${+commands[fzf-tmux]} -eq 1 ]] && fzf_cmd=(fzf-tmux $=FZF_TMUX_OPTS --)
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "$cmd" | "${fzf_cmd[@]}" --preview "$_FZF_PREVIEW_CMD") || return
  LBUFFER+="$result"
  zle reset-prompt
}

if has fzf; then
  zle -N _fzf_file_no_hidden
  bindkey '^F' _fzf_file_no_hidden
fi

fcd() {
  local dir_cmd dir
  local fzf_cmd=(fzf)

  if has fd; then
    dir_cmd='fd --type d --hidden --strip-cwd-prefix'
  elif has fdfind; then
    dir_cmd='fdfind --type d --hidden --strip-cwd-prefix'
  else
    dir_cmd='find . -type d'
  fi

  [[ -n "${TMUX_PANE:-}" && -n "${FZF_TMUX_OPTS:-}" && ${+commands[fzf-tmux]} -eq 1 ]] && fzf_cmd=(fzf-tmux $=FZF_TMUX_OPTS --)
  dir=$(eval "$dir_cmd" | "${fzf_cmd[@]}" --preview 'printf "%s\n" {}') || return
  [[ -n "$dir" ]] && cd "$dir"
}

# ------------------------------ functions -----------------------------
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

goinit() {
  local repository rootdir module_path

  repository="${PWD:t}"
  rootdir="${PWD:h:t}"
  module_path="github.com/$rootdir/$repository"

  go mod init "$module_path"
  echo "go mod init $module_path"
}

nowat() {
  echo "$1" "$(date "+%A, %B %e, %Y, %l:%M:%S%p")"
}

epoch() {
  date +%s
}

myip() {
  local external_ip local_ip

  if command -v ipconfig >/dev/null 2>&1; then
    local_ip=$(ipconfig getifaddr en0 2>/dev/null)
  elif command -v ip >/dev/null 2>&1; then
    local_ip=$(ip -4 route get 1.1.1.1 2>/dev/null)
    case "$local_ip" in
      *" src "*) local_ip=${local_ip#*" src "}; local_ip=${local_ip%% *} ;;
      *) local_ip= ;;
    esac
  fi
  external_ip=$(dig +short myip.opendns.com @resolver4.opendns.com 2>/dev/null)

  printf 'External: %s\n' "${external_ip:-unavailable}"
  printf 'Local: %s\n' "${local_ip:-unavailable}"
}

isosec() {
  TZ="GMT" date +"%Y%m%d%H%M%S" "$@"
}

dtag() {
  local when epoch

  when="$*"
  [[ -z "$when" ]] && read "when?Event local time (YYYY-MM-DD HH:MM): "
  if [[ -z "$when" ]]; then
    echo "usage: dtag YYYY-MM-DD HH:MM" >&2
    return 1
  fi

  epoch=$(date -d "$when" +%s) || return 1
  echo "Discord tag for your local time $when - copy this into the chat box:"
  echo "<t:$epoch:F>"
}

termopacity() {
  local value config link_target tmp

  if [[ $# -ne 1 ]]; then
    echo "usage: termopacity 0..1" >&2
    return 2
  fi

  value="$1"
  if ! awk -v value="$value" 'BEGIN { exit !(value ~ /^(0(\.[0-9]+)?|1(\.0+)?|\.[0-9]+)$/) }'; then
    echo "termopacity: value must be from 0 to 1" >&2
    return 2
  fi

  config="${GHOSTTY_CONFIG:-$HOME/.config/ghostty/config}"
  if [[ -L "$config" ]]; then
    link_target=$(readlink "$config") || return 1
    [[ "$link_target" == /* ]] || link_target="${config:h}/$link_target"
    config="$link_target"
  fi

  command mkdir -p "${config:h}"
  tmp="${config}.tmp.$$"
  if [[ -e "$config" ]] && command grep -q '^background-opacity[[:space:]]*=' "$config"; then
    awk -v value="$value" '
      /^background-opacity[[:space:]]*=/ && !updated {
        print "background-opacity = " value
        updated = 1
        next
      }
      { print }
    ' "$config" > "$tmp" || {
      command rm -f "$tmp"
      return 1
    }
  else
    {
      [[ -e "$config" ]] && cat "$config"
      print -r -- "background-opacity = $value"
    } > "$tmp" || {
      command rm -f "$tmp"
      return 1
    }
  fi

  command mv -f "$tmp" "$config" || return 1

  if [[ -n "${CMUX_WORKSPACE_ID:-}" ]] && command -v cmux >/dev/null 2>&1; then
    cmux reload-config || return 1
  fi

  print -r -- "background-opacity = $value"
}

rgb() {
  printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"
}

rgbg() {
  printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"
}

colors() {
  awk -v term_cols="${width:-$(tput cols || echo 80)}" 'BEGIN{
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

# ------------------------------- prompt -------------------------------
# Starship uses ~/.config/starship.toml.
if has starship; then
  eval "$(starship init zsh)"
fi
