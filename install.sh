#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
[[ "${TRACE:-}" ]] && set -o xtrace

###
# Configure this list to add new setups in necessary order
###
readonly setup_ordered_list=(
    setup_dotfiles
    setup_personal_hooks
    setup_touchid_sudo
    setup_brew
    setup_apt
    setup_oh_my_zsh
    setup_golang
    setup_ruby
    setup_rectangle
    setup_node
)

readonly manual_only_setups=(
    setup_dns
    setup_krew
)

WORKSTATION_FOCUS="${WORKSTATION_FOCUS:-"NOFOCUS"}"
WORKSTATION_SKIP="${WORKSTATION_SKIP:-"NOSKIP"}"

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###
# Load installers
###
for f in "${__dir}"/installers/*.sh; do source "$f"; done

run_setups=()
skip_setups=()
available_profiles=()
installed_profiles=()
profile_install_dir="${HOME}/.localrc.d/station_profiles"

create_run_plan() {
    local setup
    local skip
    local focus
    local default_skip
    local skipit

    # turn skip list into array if it isn't already
    if ! declare -p WORKSTATION_SKIP 2>/dev/null | grep -q '^declare \-a'; then
        read -r -a WORKSTATION_SKIP <<<"$WORKSTATION_SKIP"
    fi

    # turn run list into array if it isn't already
    if ! declare -p WORKSTATION_FOCUS 2>/dev/null | grep -q '^declare \-a'; then
        read -r -a WORKSTATION_FOCUS <<<"$WORKSTATION_FOCUS"
    fi

    if [[ "$WORKSTATION_FOCUS" != "NOFOCUS" ]]; then
        default_skip=true
    else
        default_skip=false
    fi

    for setup in "${setup_ordered_list[@]}"; do
        skipit="$default_skip"

        for skip in "${WORKSTATION_SKIP[@]}"; do
            if [[ "$setup" == *"$skip"* ]]; then
                skipit=true
                break
            fi
        done

        for focus in "${WORKSTATION_FOCUS[@]}"; do
            if [[ "$setup" == *"$focus"* ]]; then
                skipit=false
                break
            fi
        done

        if [[ "$skipit" = true ]]; then
            skip_setups+=("$setup")
        else
            run_setups+=("$setup")
        fi
    done

    for setup in "${manual_only_setups[@]}"; do
        skipit=true

        for focus in "${WORKSTATION_FOCUS[@]}"; do
            if [[ "$setup" == *"$focus"* ]]; then
                skipit=false
                break
            fi
        done

        if [[ "$skipit" = true ]]; then
            skip_setups+=("$setup")
        else
            run_setups+=("$setup")
        fi
    done
}

init_profiles() {
    local profile

    mkdir -p "${profile_install_dir}"

    shopt -s nullglob

    for profile in "${__dir}"/profiles/*.zsh; do
        available_profiles+=("$(basename -s '.zsh' "${profile}")")
    done

    for profile in "${profile_install_dir}"/*.zsh; do
        installed_profiles+=("$(basename -s '.zsh' "${profile}")")
    done

    shopt -u nullglob
}

install_profile() {
    local profile="$1"
    cp -f "${__dir}/profiles/${profile}.zsh" "${profile_install_dir}/${profile}.zsh"
}

refresh_installed_profiles() {
    [[ "${#installed_profiles[@]}" -eq 0 ]] && return

    local profile
    local installed_profile
    local available_profile
    local match
    local to_install=()
    local unmatched=()

    for installed_profile in "${installed_profiles[@]}"; do
        match=false

        for available_profile in "${available_profiles[@]}"; do
            if [[ "$installed_profile" == "$available_profile" ]]; then
                match=true
                break
            fi
        done

        if [[ "$match" == true ]]; then
            to_install+=("$installed_profile")
        else
            unmatched+=("$installed_profile")
        fi
    done

    echo "Refreshing profiles: ${to_install[*]:-(none)}"
    if [[ "${#unmatched[@]}" -gt 0 ]]; then
        echo "Defunct profiles: ${unmatched[*]}"
    fi

    [[ "${#to_install[@]}" -eq 0 ]] && return

    for profile in "${to_install[@]:-}"; do
        install_profile "$profile"
    done
}

source_profiles() {
    [[ "${#installed_profiles[@]}" -eq 0 ]] && return
    local profile
    for profile in "${installed_profiles[@]}"; do
        source "${profile_install_dir}/${profile}.zsh"
    done
}

print_outro() {
    cat <<EOF

+======================================+
| Great job! You win some extra setup! |
+======================================+

Configure iTerm (Preferences > General > Preferences)
${__dir}/assets/iterm

Install Powerlevel10k fonts (may need to remove ~/.p10k.zsh to trigger font install)
p10k configure

Install DNS over HTTPS profile
open /System/Library/PreferencePanes/Profiles.prefPane

Reload Terminal
exec zsh
EOF
}

print_setup_list() {
    local header="$1"
    local -a list=("${!2:-(none)}")
    local indent="    "

    echo "$header"

    for item in "${list[@]}"; do
        # display item with indent and remove 'setup_' prefix
        echo "${indent}${item#"setup_"}"
    done
}

print_available_setups() {
    local merged=("${setup_ordered_list[@]}" "${manual_only_setups[@]}")
    print_setup_list "Available configurations:" merged[@]
    echo
}

print_skipped_setups() {
    print_setup_list "Configurations being skipped:" skip_setups[@]
    echo
}

print_run_setups() {
    print_setup_list "Configurations being run:" run_setups[@]
    echo
}

main() {
    local setup

    init_profiles
    refresh_installed_profiles
    source_profiles

    create_run_plan

    print_available_setups
    print_skipped_setups
    print_run_setups

    # execute setups
    for setup in "${run_setups[@]:-:}"; do
        "$setup"
    done

    print_outro
}

# can include this script as a library
[[ "$0" != "$BASH_SOURCE" ]] || main
