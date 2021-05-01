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

