#!/usr/bin/env bash

setup_brew() {
    if command -v brew >/dev/null; then
        brew bundle install
    else
        echo "Skipping brew...not installed"
    fi
}
