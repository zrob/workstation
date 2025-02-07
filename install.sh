#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
[[ "${TRACE:-}" ]] && set -o xtrace

###
# Configure this list to add new setups in necessary order
###
readonly setup_ordered_list=(
    setup_dns
    setup_brew
    setup_apt
    setup_oh_my_zsh
    setup_golang
    setup_ruby
    setup_dotfiles
    setup_rectangle
    setup_personal_hooks
    setup_krew
    setup_touchid_sudo
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
            local initial_rev new_rev
            initial_rev=$(git rev-parse HEAD)
            git pull
            new_rev=$(git rev-parse HEAD)
            if [[ "$initial_rev" != "$new_rev" ]]; then
                local commit_url
                commit_url=$(git remote get-url origin)

cat <<EOF

+============================================+
| Powerlevel10k updates                      |
+============================================+

Commits: ${commit_url%.git}/commits/master

EOF
                git --no-pager log --abbrev-commit --pretty=oneline "$initial_rev"..."$new_rev"
                echo
            fi
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
    ruby-install --latest #> "$logfile" 2>&1
    ruby-install --cleanup --no-reinstall ruby #>> "$logfile" 2>&1

    # if ! grep "Ruby is already installed" "$logfile" >/dev/null; then
    #     installed_version=$(grep "Successfully installed ruby" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
    #     echo "$installed_version" > "${HOME}/.ruby-version"
    # else
    #     installed_version=$(grep "Ruby is already installed" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
    #     echo "$installed_version" > "${HOME}/.ruby-version"
    # fi

    # chruby doesn't play nice with nounset
    # set +o nounset
    # if command -v brew >/dev/null; then
    #     source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
    # else
    #     source /usr/local/share/chruby/chruby.sh
    # fi
    # chruby "$(cat "${HOME}/.ruby-version")"
    # chruby
    # set -o nounset

    # gem install bundler --no-document

    # tail -n 1 "$logfile"
}

setup_dotfiles() {
    cp -f "${__dir}/dotfiles/.gitconfig" ~/.gitconfig
    cp -f "${__dir}/dotfiles/.zshrc" ~/.zshrc
    cp -f "${__dir}/dotfiles/.p10k.zsh" ~/.p10k.zsh
    cp -f "${__dir}/dotfiles/.nanorc" ~/.nanorc
    cp -f "${__dir}/dotfiles/.gemrc" ~/.gemrc
}

setup_rectangle() {
    local filename="RectangleConfig.json"
    local source_prefs="${__dir}/assets/rectangle/${filename}"
    local dest_prefs_folder="${HOME}/Library/Application Support/Rectangle"

    mkdir -p "${dest_prefs_folder}"
    rm -fr "${dest_prefs_folder}"/*
    cp "${source_prefs}"  "${dest_prefs_folder}/${filename}" >/dev/null 2>&1
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

    networksetup -setdnsservers Wi-Fi $(echo "${setdns}" | xargs)
}

setup_touchid_sudo() {
    if [[ -f "/etc/pam.d/sudo" ]] && ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
        cat /etc/pam.d/sudo | \
            sed 's/auth       sufficient     pam_smartcard.so/& \nauth sufficient pam_tid.so/' | \
            sudo tee /etc/pam.d/sudo >/dev/null
    fi
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
