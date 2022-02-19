#!/usr/bin/env bash

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

# add google cloud signing key
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# add kubernetes repo
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update && sudo apt-get install -y \
    direnv \
    fzf \
    git \
    jq \
    kubectl \
    ncdu \
    python3 \
    silversearcher-ag \
    socat \
    thefuck \
    tree \
    watch \
    wget \
    zsh-syntax-highlighting

# No apt analogs, just skipping
    # kind
    # mdcat
