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
  chruby
  direnv
  docker
  fzf
  nvm
  z
  zsh-autosuggestions
)
plugins+=(zsh-syntax-highlighting) #ensure this plugin is listed last

# load nvm on first use of nvm/node/npm/npx/etc. add other npm global commands to lazy-cmd
zstyle ':omz:plugins:nvm' lazy yes

source "${ZSH}/oh-my-zsh.sh"

# put nvm's default node on PATH without loading nvm, so the prompt (and node scripts) see it.
# nvm itself still loads lazily on first use of nvm/node/npm/npx
() {
  local dir=${NVM_DIR:-$HOME/.nvm} v
  [[ -r $dir/alias/default ]] && v=$(<$dir/alias/default)
  case $v in
    (node|stable) v=( $dir/versions/node/v<->.<->.<->(N/nOn[1]:t) ) ;;  # newest stable, like nvm
    (v<->.<->.<->) ;;
    (<->.<->.<->) v=v$v ;;
    (*) v= ;;  # partial versions, lts/*, etc: leave to nvm
  esac
  [[ -n $v && -x $dir/versions/node/$v/bin/node ]] && path=($dir/versions/node/$v/bin $path)
}

####################
# User configuration
####################

is(){command -v "$1" >/dev/null}
in-container() {
  # cgroup v1
  ( cat /proc/1/cgroup 2>/dev/null | grep -q docker ) ||
  # cgroup v2
  # will always have cgroup.events, but only containers have /sys/fs/cgroup/cgroup.type so look for both to exist
  # this isn't really true on older kernels or could change on future, but is good enough
  ( [[ -r /sys/fs/cgroup/cgroup.events ]] && [[ -r /sys/fs/cgroup/cgroup.type ]] )
}

export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
export ZSH_HIGHLIGHT_STYLES[bracket-error]='bg=red'

export PATH="${PATH}:${HOME}/.workstation/bin"
export EDITOR=nano
export TERM=xterm-256color

export GOPATH="${HOME}/workspace/go"
export PATH="${PATH}:${GOPATH}/bin"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

[[ "$OSTYPE" == linux* ]] && in-container && export __WORKSTATION_IN_CONTAINER=true

alias g=git
alias ga="git a"
alias gci="git ci"
alias gd="git d"
alias glg="git lg"
alias gs="git s"

alias k=kubectl
# brew installs _kubectl into site-functions; only generate it where nothing provides one (apt)
if is kubectl && (( ! $+_comps[kubectl] )); then
  source <(kubectl completion zsh)
fi

alias chat='mkdir -p "${HOME}/tmp/chat" && cd "${HOME}/tmp/chat" && claude'

alias f=fuck
# load thefuck's alias on first use instead of on every shell start
if is thefuck; then
  fuck() { unfunction fuck; eval "$(thefuck --alias)"; fuck "$@" }
fi

# Setup hooks for config and binaries on local machine
[[ -r "${HOME}/.localrc" ]] && source "${HOME}/.localrc"
[[ -d "${HOME}/.localrc.d" ]] && {
  for f in "${HOME}"/.localrc.d/**/*.zsh; do source "$f"; done
  unset f
}
[[ -d "${HOME}/bin" ]] && export PATH="${PATH}:${HOME}/bin"

# Setup location of diff-highlight for .gitconfig
if [[ -n "${HOMEBREW_PREFIX:-}" && -d "${HOMEBREW_PREFIX}/opt/git" ]]; then
  # same path `brew --prefix git` returns, without running brew
  export __WORKSTATION_DIFF_HIGHLIGHT_PREFIX="${HOMEBREW_PREFIX}/opt/git"
elif is brew; then
  export __WORKSTATION_DIFF_HIGHLIGHT_PREFIX="$(brew --prefix git)"
else
  export __WORKSTATION_DIFF_HIGHLIGHT_PREFIX="/usr"
fi

unset -f is
unset -f in-container

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
