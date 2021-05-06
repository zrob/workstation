#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew_bundle() {
    brew bundle install
}

setup_oh_my_zsh() {
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
    else
        # this assumes oh my zsh is running well and setting $ZSH
        # if things are broke, then may need to manually tinker
        "${ZSH}/tools/upgrade.sh"
    fi

    local custom_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    if [ ! -d "${custom_dir}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${custom_dir}/themes/powerlevel10k"
    else
        pushd "${custom_dir}/themes/powerlevel10k"
            git pull
        popd
    fi

    if [ ! -d "${custom_dir}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${custom_dir}/plugins/zsh-syntax-highlighting"
    else
        pushd "${custom_dir}/plugins/zsh-syntax-highlighting"
            git pull
        popd
    fi

    if [ ! -d "${custom_dir}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "${custom_dir}/plugins/zsh-autosuggestions"
    else
        pushd "${custom_dir}/plugins/zsh-autosuggestions"
            git pull
        popd
    fi
}

setup_golang() {
    local gopath="${HOME}/workspace/go"
    mkdir -p "${gopath}/src"
    mkdir -p "${gopath}/bin"
}

setup_ruby() {
    local logfile="${__dir}/logs/ruby-install.log"
    local installed_version

    mkdir -p "${__dir}/logs"

    # install latest ruby
    echo "Installing ruby. Logs are in '${logfile}'"
    ruby-install --cleanup --no-reinstall ruby > "$logfile" 2>&1

    if ! grep "Ruby is already installed" "$logfile" >/dev/null; then
        installed_version=$(grep "Successfully installed ruby" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" > "${HOME}/.ruby-version"
    else
        installed_version=$(grep "Ruby is already installed" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" > "${HOME}/.ruby-version"
    fi

    # chruby doesn't play nice with nounset
    set +o nounset
    source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
    chruby $(cat "${HOME}/.ruby-version")
    chruby
    set -o nounset

    gem install bundler --no-document

    tail -n 1 "$logfile"
}

setup_dotfiles() {
    cp -f "${__dir}/dotFiles/.gitconfig" ~/.gitconfig
    cp -f "${__dir}/dotFiles/.zshrc" ~/.zshrc
    cp -f "${__dir}/dotFiles/.p10k.zsh" ~/.p10k.zsh
    cp -f "${__dir}/dotFiles/.nanorc" ~/.nanorc
    cp -f "${__dir}/dotFiles/.gemrc" ~/.gemrc
}

setup_spectacle() {
    local desired_prefs="${__dir}/assets/spectacle/Shortcuts.json"
    local current_prefs="${HOME}/Library/Application Support/Spectacle/Shortcuts.json"

    if ! diff "${desired_prefs}" "${current_prefs}" >/dev/null 2>&1; then
        cp -f "${desired_prefs}" "${current_prefs}"
    fi
}

setup_personal_hooks() {
    # setup a place to drop binaries on local workstation
    # that will be in path but not checked into this repo
    # ~/bin.personal
    mkdir -p "${HOME}/bin.personal"

    # setup a place to drop local config like env and alias
    # that will be sourced but not checked into this repo
    # ~/.localrc
    if [ ! -f "${HOME}/.localrc" ]; then
        echo "# Store local configuration here. This is sourced by .zshrc" > "${HOME}/.localrc"
    fi
}

print_outro() {
cat << EOF

+==================================+
Great job! You win some extra setup!
+==================================+

Configure iTerm (Preferences > General > Preferences)
${__dir}/assets/iterm

Install Powerlevel10k fonts (may need to remove ~/.p10k.zsh to trigger font install)
p10k configure

Reload Terminal
source ~/.zshrc"
EOF
}

main() {
    brew_bundle
    setup_oh_my_zsh
    setup_golang
    setup_ruby
    setup_dotfiles
    setup_spectacle
    setup_personal_hooks
    print_outro
}

main
