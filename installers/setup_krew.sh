#!/usr/bin/env bash

setup_krew() {
    local os arch krew

    os="$(uname | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
    krew="krew-${os}_${arch}"

    KREW_TMPDIR="$(mktemp -d)"
    trap '{ rm -rf -- "${KREW_TMPDIR}"; }' EXIT

    cd "${KREW_TMPDIR}"
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew}.tar.gz"
    tar zxvf "${krew}.tar.gz"

    ./"${krew}" install krew
    ./"${krew}" update
    # tree doesn't have an arm distro and i want my dev container build to work so just be lazy and ignore the error
    set +o errexit
    ./"${krew}" install tree
    set -o errexit
    ./"${krew}" install lineage
    ./"${krew}" upgrade
}
