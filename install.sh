#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install Homebrew stuff

brew bundle install

# Install oh my zsh and powerlevel10k theme

if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Copy dotfiles

cp -f ${__dir}/dotFiles/.gitconfig ~/.gitconfig
cp -f ${__dir}/dotFiles/.zshrc ~/.zshrc
cp -f ${__dir}/dotFiles/.p10k.zsh ~/.p10k.zsh

# Setup spectacle

desired_prefs="${__dir}/assets/com.divisiblebyzero.Spectacle.plist"
current_prefs="${HOME}/Library/Preferences/com.divisiblebyzero.Spectacle.plist"

if ! diff "${desired_prefs}" "${current_prefs}"; then
	cp -f "${desired_prefs}" "${current_prefs}"
fi

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