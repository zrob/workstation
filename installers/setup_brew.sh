#!/usr/bin/env bash

setup_brew() {
    if command -v brew >/dev/null; then
        HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew bundle install
    else
        echo "Skipping brew...not installed"
    fi
}
