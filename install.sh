#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
[[ "${TRACE:-}" ]] && set -o xtrace

###
# Configure this list to add new setups in necessary order
###
readonly setup_ordered_list=(
    setup_brew
    setup_apt
    setup_oh_my_zsh
    setup_golang
    setup_ruby
    setup_dotfiles
    setup_spectacle
    setup_personal_hooks
)

WORKSTATION_FOCUS="${WORKSTATION_FOCUS:-"NOFOCUS"}"
WORKSTATION_SKIP="${WORKSTATION_SKIP:-"NOSKIP"}"

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    if ! declare -p WORKSTATION_SKIP 2> /dev/null | grep -q '^declare \-a'; then
        read -a WORKSTATION_SKIP <<< "$WORKSTATION_SKIP"
    fi

    # turn run list into array if it isn't already
    if ! declare -p WORKSTATION_FOCUS 2> /dev/null | grep -q '^declare \-a'; then
        read -a WORKSTATION_FOCUS <<< "$WORKSTATION_FOCUS"
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
    [[ "${#installed_profiles[@]}" -eq  0 ]] && return

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

    [[ "${#to_install[@]}" -eq  0 ]] && return

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

setup_brew() {
    if command -v brew >/dev/null; then
        brew bundle install
    else
        echo "Skipping brew...not installed"
    fi
}

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

setup_oh_my_zsh() {
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
    else
        "${HOME}/.oh-my-zsh/tools/upgrade.sh"
    fi

    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "${custom_dir}/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${custom_dir}/themes/powerlevel10k"
    else
        pushd "${custom_dir}/themes/powerlevel10k"
            git pull
        popd
    fi
    # gitstatusd is usually installed first time login happens after p10k install
    # instead force the issue, b/c it's annoying inside containers and requires network access
    "${custom_dir}"/themes/powerlevel10k/gitstatus/install

    if [[ ! -d "${custom_dir}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${custom_dir}/plugins/zsh-syntax-highlighting"
    else
        pushd "${custom_dir}/plugins/zsh-syntax-highlighting"
            git pull
        popd
    fi

    if [[ ! -d "${custom_dir}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "${custom_dir}/plugins/zsh-autosuggestions"
    else
        pushd "${custom_dir}/plugins/zsh-autosuggestions"
            git pull
        popd
    fi
}

setup_golang() {
    local gopath="${HOME}/workspace/go"
    mkdir -p "${gopath}/src"
    mkdir -p "${gopath}/bin"
}

setup_ruby() {
    local logfile="${__dir}/logs/ruby-install.log"
    local installed_version

    mkdir -p "${__dir}/logs"

    # install latest ruby
    echo "Installing ruby. Logs are in '${logfile}'"
    ruby-install --latest > "$logfile" 2>&1
    ruby-install --cleanup --no-reinstall ruby >> "$logfile" 2>&1

    if ! grep "Ruby is already installed" "$logfile" >/dev/null; then
        installed_version=$(grep "Successfully installed ruby" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" > "${HOME}/.ruby-version"
    else
        installed_version=$(grep "Ruby is already installed" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" > "${HOME}/.ruby-version"
    fi

    # chruby doesn't play nice with nounset
    set +o nounset
    if command -v brew >/dev/null; then
        source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
    else
        source /usr/local/share/chruby/chruby.sh
    fi
    chruby "$(cat "${HOME}/.ruby-version")"
    chruby
    set -o nounset

    gem install bundler --no-document

    tail -n 1 "$logfile"
}

setup_dotfiles() {
    cp -f "${__dir}/dotfiles/.gitconfig" ~/.gitconfig
    cp -f "${__dir}/dotfiles/.zshrc" ~/.zshrc
    cp -f "${__dir}/dotfiles/.p10k.zsh" ~/.p10k.zsh
    cp -f "${__dir}/dotfiles/.nanorc" ~/.nanorc
    cp -f "${__dir}/dotfiles/.gemrc" ~/.gemrc
}

setup_spectacle() {
    local desired_prefs="${__dir}/assets/spectacle/Shortcuts.json"
    local current_prefs="${HOME}/Library/Application Support/Spectacle/Shortcuts.json"

    if ! diff "${desired_prefs}" "${current_prefs}" >/dev/null 2>&1; then
        cp -f "${desired_prefs}" "${current_prefs}"
    fi
}

setup_personal_hooks() {
    # setup a place to drop binaries on local workstation
    # that will be in path but not checked into this repo
    # ~/bin
    mkdir -p "${HOME}/bin"

    # setup a place to drop local config like env and alias
    # that will be sourced but not checked into this repo
    # ~/.localrc
    if [[ ! -f "${HOME}/.localrc" ]]; then
        echo "# Store local configuration here. This is sourced by .zshrc" > "${HOME}/.localrc"
    fi

    # setup a directory to drop local config .zsh files
    # that will be sourced by .zshrc but not check in
    # ~/.localrc.d
    mkdir -p "${HOME}/.localrc.d"
}

print_outro() {
cat << EOF

+======================================+
| Great job! You win some extra setup! |
+======================================+

Configure iTerm (Preferences > General > Preferences)
${__dir}/assets/iterm

Install Powerlevel10k fonts (may need to remove ~/.p10k.zsh to trigger font install)
p10k configure

Reload Terminal
source ~/.zshrc
EOF
}

print_setup_list() {
    local header="$1"
    local -a list=("${!2:-(none)}")
    local indent="    "

    echo "$header"

    for item in "${list[@]}"; do
        # display item with indent and remove 'setup_' prefix
        echo "${indent}${item#"setup_"}";
    done
}

print_available_setups() {
    print_setup_list "Available configurations:" setup_ordered_list[@]
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
