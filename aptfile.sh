#!/usr/bin/env bash

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

sudo apt-get update && sudo apt-get install -y \
    direnv \
    fzf \
    git \
    jq \
    ncdu \
    socat \
    silversearcher-ag \
    thefuck \
    tree \
    watch \
    wget \
    zsh-syntax-highlighting \
    python3 \
    && sudo rm -rf /var/lib/apt/lists/*

# No apt analogs, just skipping
    # kind
    # mdcat