#!/usr/bin/env bash

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

sudo apt-get update && apt-get install -y \
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
    zsh-syntax-highlighting

# No apt analogs, just skipping
    # kind
    # mdcat