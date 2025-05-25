#!/usr/bin/env bash

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
