#!/usr/bin/env bash

# system-scoped profiles don't show in `profiles list` without root, but their
# payload identifiers are recorded in the world-readable network extension prefs
doh_profile_installed() {
    plutil -p /Library/Preferences/com.apple.networkextension.plist 2>/dev/null | grep -q "\"$1\""
}

setup_doh_policy() {
    if [[ "$(uname)" != Darwin ]]; then
        echo "Skipping doh policy...not macOS"
        return
    fi

    # if ! doh_profile_installed com.zach.cloudflare.doh; then
    #     open "${__dir}/assets/osx-dns-profile/cloudflare-doh.mobileconfig"
    # fi

    if ! doh_profile_installed com.zach.quad9.doh; then
        open "${__dir}/assets/osx-dns-profile/quad9-doh.mobileconfig"
    fi
}
