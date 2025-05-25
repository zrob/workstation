#!/usr/bin/env bash

setup_touchid_sudo() {
    if [[ -f "/etc/pam.d/sudo" ]] && ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
        cat /etc/pam.d/sudo |
            sed 's/auth       sufficient     pam_smartcard.so/& \nauth sufficient pam_tid.so/' |
            sudo tee /etc/pam.d/sudo >/dev/null
    fi
}
