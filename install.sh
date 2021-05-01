#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install Homebrew stuff

brew bundle install

# Copy dotfiles

cp -f ${__dir}/dotFiles/.gitconfig ~/.gitconfig

# Setup spectacle

desired_prefs="${__dir}/assets/com.divisiblebyzero.Spectacle.plist"
current_prefs="${HOME}/Library/Preferences/com.divisiblebyzero.Spectacle.plist"

if ! diff "${desired_prefs}" "${current_prefs}"; then
	cp -f "${desired_prefs}" "${current_prefs}"
fi