#!/usr/bin/env bash

setup_brew() {
    if command -v brew >/dev/null; then
        local before
        before=$(drift_tmp)
        drift_brew_versions >"$before" || true

        HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew bundle install

        drift_check_brew_upgrades "$before" || true
        drift_check_brew_untracked "${__dir}/Brewfile" || true
        rm -f "$before"
    else
        echo "Skipping brew...not installed"
    fi
}
