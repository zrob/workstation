#!/usr/bin/env bash

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

# add keys for kubernetes repos
# used for packages: kubectl
readonly kubernetes_latest=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
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
