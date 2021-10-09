# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#################
# Setup Oh My Zsh
#################

export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  docker
  fzf
  git-prompt
  z
  zsh-autosuggestions
)
plugins+=(zsh-syntax-highlighting) #ensure this plugin is listed last

source "${ZSH}/oh-my-zsh.sh"

####################
# User configuration
####################

is(){command -v "$1" >/dev/null}
in-container(){cat /proc/1/cgroup 2>/dev/null | grep -q docker}

export PATH="${PATH}:${HOME}/.workstation/bin"
export EDITOR=nano
export TERM=xterm-256color

export GOPATH="${HOME}/workspace/go"
export PATH="${PATH}:${GOPATH}/bin"

in-container && export __WORKSTATION_IN_CONTAINER=true

alias g=git
alias ga="git a"
alias gci="git ci"
alias gd="git d"
alias glg="git lg"
alias gs="git s"

alias k=kubectl
if is kubectl; then
  source <(kubectl completion zsh)
  complete -F __start_kubectl k
fi

alias f=fuck
if is thefuck; then
  source <(thefuck --alias)
fi

if is direnv; then
  source <(direnv hook zsh)
fi

if is brew && [[ -d "$(brew --prefix)/opt/chruby" ]]; then
  source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
  source "$(brew --prefix)/opt/chruby/share/chruby/auto.sh"
elif [[ -r "/usr/local/share/chruby/chruby.sh" ]]; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
fi

# Setup hooks for config and binaries on local machine
[[ -r "${HOME}/.localrc" ]] && source "${HOME}/.localrc"
[[ -d "${HOME}/.localrc.d" ]] && {
  for f in "${HOME}"/.localrc.d/**/*.zsh; do source "$f"; done
  unset f
}
[[ -d "${HOME}/bin" ]] && export PATH="${PATH}:${HOME}/bin"

# Setup location of diff-highlight for .gitconfig
if is brew; then
  export __WORKSTATION_DIFF_HIGHLIGHT_PREFIX="$(brew --prefix git)"
else
  export __WORKSTATION_DIFF_HIGHLIGHT_PREFIX="/usr"
fi

unset -f is
unset -f in-container

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
