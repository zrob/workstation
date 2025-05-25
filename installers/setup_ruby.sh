#!/usr/bin/env bash

setup_ruby() {
    local logfile="${__dir}/logs/ruby-install.log"
    local installed_version

    mkdir -p "${__dir}/logs"

    # install latest ruby
    echo "Installing ruby. Logs are in '${logfile}'"
    ruby-install --latest >"$logfile" 2>&1
    ruby-install --cleanup --no-reinstall ruby >>"$logfile" 2>&1

    if ! grep "Ruby is already installed" "$logfile" >/dev/null; then
        installed_version=$(grep "Successfully installed ruby" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" >"${HOME}/.ruby-version"
    else
        installed_version=$(grep "Ruby is already installed" "$logfile" | awk '{n=split($0,A,"\/"); print A[n]}')
        echo "$installed_version" >"${HOME}/.ruby-version"
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
