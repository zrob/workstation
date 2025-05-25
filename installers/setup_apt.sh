#!/usr/bin/env bash

setup_apt() {
    # apt is a special case. only use if brew isn't available.
    if command -v brew >/dev/null; then
        echo "Skipping apt...brew is available"
        return
    fi
    if ! command -v apt-get >/dev/null; then
        echo "Skipping apt...apt-get not available"
        return
    fi
    "${__dir}"/aptfile.sh
}
