#!/usr/bin/env bash

setup_node() {
    export NVM_DIR="$HOME/.nvm"

    mkdir -p "${NVM_DIR}"

    pushd "${NVM_DIR}"
        if ! git status > /dev/null 2>&1; then  
            git clone https://github.com/nvm-sh/nvm.git .
        fi

        git fetch --tags origin
        git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
    popd

    source "$NVM_DIR/nvm.sh"

    nvm install node
    nvm alias default node
}