#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install Homebrew and install all the homebrew things

if ! command -v brew &> /dev/null
then
    echo "'brew' could not be found. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install

# Copy dotfiles

cp -f ${__dir}/dotFiles/.gitconfig ~/.gitconfig

