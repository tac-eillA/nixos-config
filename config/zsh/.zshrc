setopt EXTENDED_GLOB
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS

HISTFILE="$HOME/.cache/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

mkdir -p "$HOME/.cache/zsh"

autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

autoload -Uz colors && colors

function git_prompt_branch() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  [[ "$branch" == "HEAD" ]] && return
  print " %{$fg[cyan]%}on%{$reset_color%} %{$fg[blue]%}${branch}%{$reset_color%}"
}

function prompt_nix_shell() {
  [[ -n "$IN_NIX_SHELL" ]] || return
  print " %{$fg[yellow]%}[nix-shell]%{$reset_color%}"
}

PROMPT='%{$fg[blue]%}%n%{$reset_color%} at %{$fg[white]%}%m%{$reset_color%} in %{$fg[magenta]%}%2~%{$reset_color%}$(git_prompt_branch)$(prompt_nix_shell)\n%{$fg_bold[cyan]%}>%{$reset_color%} '
RPROMPT='%{$fg[green]%}%*%{$reset_color%}'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if [[ -f /run/current-system/sw/share/fzf/key-bindings.zsh ]]; then
  source /run/current-system/sw/share/fzf/key-bindings.zsh
fi
if [[ -f /run/current-system/sw/share/fzf/completion.zsh ]]; then
  source /run/current-system/sw/share/fzf/completion.zsh
fi

alias cls='clear'
alias lg='lazygit'
alias ta='tmux attach -t main || tmux new -s main'

export NIXCFG_DIR="${NIXOS_CONFIG_REPO:-/etc/nixos}"

function nrh() {
  print "nrb  -> build current host"
  print "nrs  -> switch current host"
  print "nrt  -> test current host"
  print "nfu  -> flake update"
  print "nfl  -> flake lock --update-input nixpkgs"
  print "nlg  -> list system generations"
  print "nrr  -> rollback and switch"
  print "nrbk -> rollback next boot"
}

function nrb() {
  sudo nixos-rebuild build --flake "${NIXCFG_DIR}#$(hostname)"
}

function nrs() {
  sudo nixos-rebuild switch --flake "${NIXCFG_DIR}#$(hostname)"
}

function nrt() {
  sudo nixos-rebuild test --flake "${NIXCFG_DIR}#$(hostname)"
}

function nfu() {
  sudo nix flake update --flake "${NIXCFG_DIR}"
}

function nfl() {
  sudo nix flake lock --update-input nixpkgs "${NIXCFG_DIR}"
}

function nlg() {
  sudo nixos-rebuild list-generations
}

function nrr() {
  sudo nixos-rebuild switch --rollback
}

function nrbk() {
  sudo nixos-rebuild boot --rollback
}

export DOOMDIR="$HOME/.config/doom"

if [[ -n "$PS1" ]] && command -v fastfetch >/dev/null 2>&1 && [[ -z "$FASTFETCH_SHOWN" ]]; then
  export FASTFETCH_SHOWN=1
  fastfetch --logo none --color blue
fi
