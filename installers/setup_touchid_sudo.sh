#!/usr/bin/env bash

# enable touch id for sudo via /etc/pam.d/sudo_local, which (unlike
# /etc/pam.d/sudo) survives macOS updates. built from apple's template.

setup_touchid_sudo() {
    local template=/etc/pam.d/sudo_local.template
    local target=/etc/pam.d/sudo_local

    if [[ ! -f "$template" ]]; then
        echo "Skipping touchid sudo...no sudo_local support (not macOS 14+)"
        return
    fi

    if grep -qE '^[[:space:]]*auth[[:space:]].*pam_tid\.so' "$target" 2>/dev/null; then
        return
    fi

    sed -E 's/^#[[:space:]]*(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)/\1/' "$template" |
        sudo tee "$target" >/dev/null
    echo "touchid sudo: enabled via ${target}"
}
