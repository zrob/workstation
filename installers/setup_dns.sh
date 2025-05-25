#!/usr/bin/env bash

setup_dns() {
    # local cloudflare="1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001"
    # if ! profiles list | grep -q com.zach.cloudflare.doh; then
    #     open "${__dir}/assets/osx-dns-profile/cloudflare-doh.mobileconfig"
    # fi

    local quad9="9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9"
    if ! profiles list | grep -q com.zach.quad9.doh; then
        open "${__dir}/assets/osx-dns-profile/quad9-doh.mobileconfig"
    fi

    local setdns="$quad9"
    if [[ -n "${WORKSTATION_DNS:-}" ]]; then
        setdns="$WORKSTATION_DNS"
    fi

    networksetup -setdnsservers Wi-Fi "$(echo "${setdns}" | xargs)"
}
