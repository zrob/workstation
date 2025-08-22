#!/usr/bin/env bash

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

# add keys for kubernetes repos
# used for packages: kubectl

# get latest and strip patch
readonly kubernetes_latest=$(curl -L -s https://dl.k8s.io/release/stable.txt | cut -d '.' -f 1,2 )
# version does not matter here, same key used for all versions
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${kubernetes_latest}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# version does matter here. different packages per minor
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${kubernetes_latest}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

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
