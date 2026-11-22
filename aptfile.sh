#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
[[ "${TRACE:-}" ]] && set -o xtrace

# Homebrew doesn't work on linux arm.
# Trying out using this to mirror brew file for linux arm.

# add keys for kubernetes repos
# used for packages: kubectl

# get latest and strip patch
kubernetes_latest=$(curl -fsSL https://dl.k8s.io/release/stable.txt | cut -d '.' -f 1,2)
if [[ ! "$kubernetes_latest" =~ ^v[0-9]+\.[0-9]+$ ]]; then
    echo "could not determine latest kubernetes version (got '${kubernetes_latest}')" >&2
    exit 1
fi
readonly kubernetes_latest
# keyrings dir only exists by default on debian 12+/ubuntu 22.04+
sudo mkdir -p -m 0755 /etc/apt/keyrings
# version does not matter here, same key used for all versions
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${kubernetes_latest}/deb/Release.key" | sudo gpg --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
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
