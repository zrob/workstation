#!/usr/bin/env bash

setup_personal_hooks() {
    # setup a place to drop binaries on local workstation
    # that will be in path but not checked into this repo
    # ~/bin
    mkdir -p "${HOME}/bin"

    # setup a place to drop local config like env and alias
    # that will be sourced but not checked into this repo
    # ~/.localrc
    if [[ ! -f "${HOME}/.localrc" ]]; then
        echo "# Store local configuration here. This is sourced by .zshrc" >"${HOME}/.localrc"
    fi

    # setup a directory to drop local config .zsh files
    # that will be sourced by .zshrc but not check in
    # ~/.localrc.d
    mkdir -p "${HOME}/.localrc.d"
}
