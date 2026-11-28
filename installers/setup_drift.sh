#!/usr/bin/env bash

# records version bumps, new macOS defaults keys and new iTerm profile settings to the drift
# journal (see lib/drift.sh), then nags only once unreviewed changes are old. review with: drift review

setup_drift() {
    drift_check_versions || true

    if [[ "$(uname)" == Darwin ]]; then
        drift_check_defaults "${__dir}/assets/macos/defaults.txt" || true
        drift_check_iterm_profile "${__dir}/assets/iterm/com.googlecode.iterm2.plist" || true
    fi

    drift_nag || true
}
