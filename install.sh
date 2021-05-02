#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install Homebrew stuff

brew bundle install

# Install and setup zsh

if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
else
    "${ZSH}/tools/upgrade.sh"
fi

custom_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

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

# Setup golang

GOPATH="${HOME}/workspace/go"
mkdir -p "${GOPATH}/src"
mkdir -p "${GOPATH}/bin"

# Copy dotfiles

cp -f "${__dir}/dotFiles/.gitconfig" ~/.gitconfig
cp -f "${__dir}/dotFiles/.zshrc" ~/.zshrc
cp -f "${__dir}/dotFiles/.p10k.zsh" ~/.p10k.zsh
cp -f "${__dir}/dotFiles/.nanorc" ~/.nanorc

# Setup spectacle

desired_prefs="${__dir}/assets/com.divisiblebyzero.Spectacle.plist"
current_prefs="${HOME}/Library/Preferences/com.divisiblebyzero.Spectacle.plist"

if ! diff "${desired_prefs}" "${current_prefs}"; then
	cp -f "${desired_prefs}" "${current_prefs}"
fi

# Setup personal config and bin

mkdir -p "${HOME}/bin.personal"
[ ! -f "${HOME}/.config.personal" ] && \
    cp "${__dir}/assets/config.personal-template" ~/.config.personal

# Manual followup

echo
echo "+==========================+"
echo "Great job! Here's some extra setup"
echo "+==========================+"
echo

echo "Configure iTerm (Preferences > General > Preferences)"
echo "${__dir}/assets/iterm"
echo

echo "Install Powerlevel10k fonts"
echo "p10k configure"
echo

echo "Reload Terminal:"
echo "source ~/.zshrc"