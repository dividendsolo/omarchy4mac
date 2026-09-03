# Omarchy 4 shell defaults, ported from omarchy default/bash/{aliases,envs}.
# Source this from ~/.zshrc. Needs: eza bat fzf zoxide (brew install).

# ---- Omarchy 4 shell defaults (ported from default/bash/aliases + envs) ----
export EDITOR="${EDITOR:-nvim}"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# File system
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

# zoxide: `cd` falls through to `z` for anything that is not a real path
eval "$(zoxide init zsh)"
zd() {
  if (( $# == 0 )); then
    builtin cd ~ || return
  elif [[ -d $1 ]]; then
    builtin cd "$1" || return
  else
    z "$@" || { echo "Error: Directory not found"; return 1; }
    printf "\U000F17A9 "
    pwd
  fi
}
alias cd='zd'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias d='docker'
alias r='rails'
alias t='tmux attach || tmux new -s Work'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

