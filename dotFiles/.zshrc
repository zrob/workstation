# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git-prompt
  z
  zsh_reload
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting # must be last
)

source $ZSH/oh-my-zsh.sh

####################
# User configuration
####################

export PATH="${PATH}:${HOME}/.workstation/bin"

export EDITOR=nano

export GOPATH="${HOME}/workspace/go"
export PATH="${PATH}:${GOPATH}/bin"

alias g=git

if command -v kubectl >/dev/null; then
  alias k=kubectl
  # kubectl auto-complete and setup for k alias
  source <(kubectl completion zsh)
  complete -F __start_kubectl k
fi

if command -v thefuck >/dev/null; then
  eval $(thefuck --alias)
fi

if command -v brew >/dev/null && [[ -d "$(brew --prefix)/opt/chruby" ]]; then
  source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
  source "$(brew --prefix)/opt/chruby/share/chruby/auto.sh"
fi

# Setup hooks for config and binaries on local machine
[[ ! -f "${HOME}/.localrc" ]] || source "${HOME}/.localrc"
[[ ! -d "${HOME}/bin" ]] || export PATH="${PATH}:${HOME}/bin"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
