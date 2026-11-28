#!/usr/bin/env bash

setup_oh_my_zsh() {
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        local omz_old omz_new
        omz_old=$(git -C "${HOME}/.oh-my-zsh" rev-parse HEAD 2>/dev/null || true)
        "${HOME}/.oh-my-zsh/tools/upgrade.sh"
        omz_new=$(git -C "${HOME}/.oh-my-zsh" rev-parse HEAD 2>/dev/null || true)

        # changes to the plugins .zshrc uses, and to the starter .zshrc templates
        local -a omz_paths=(templates/)
        local plugin
        while read -r plugin; do
            omz_paths+=("plugins/${plugin}/")
        done < <(awk '/^plugins=\(/ { on = 1; next } on && /^\)/ { exit } on && NF { print $1 }' "${__dir}/dotfiles/.zshrc")

        drift_record_upstream oh-my-zsh "${HOME}/.oh-my-zsh" "$omz_old" "$omz_new" "${omz_paths[@]}" || true
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
    # template and wizard changes since .p10k.zsh was last merged (assets/p10k/merged-base)
    drift_check_p10k "${custom_dir}/themes/powerlevel10k" "${__dir}/assets/p10k/merged-base" || true
    # gitstatusd is usually installed first time login happens after p10k install
    # instead force the issue, b/c it's annoying inside containers and requires network access
    "${custom_dir}"/themes/powerlevel10k/gitstatus/install

    if [[ ! -d "${custom_dir}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${custom_dir}/plugins/zsh-syntax-highlighting"
    else
        pushd "${custom_dir}/plugins/zsh-syntax-highlighting"
            local hl_old
            hl_old=$(git rev-parse HEAD)
            git pull
            # options are documented in the README and docs/
            drift_record_upstream zsh-syntax-highlighting "$PWD" "$hl_old" "$(git rev-parse HEAD)" README.md docs/ || true
        popd
    fi

    if [[ ! -d "${custom_dir}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "${custom_dir}/plugins/zsh-autosuggestions"
    else
        pushd "${custom_dir}/plugins/zsh-autosuggestions"
            local as_old
            as_old=$(git rev-parse HEAD)
            git pull
            # options (strategies, buffer size, ignore patterns) are documented in the README
            drift_record_upstream zsh-autosuggestions "$PWD" "$as_old" "$(git rev-parse HEAD)" README.md || true
        popd
    fi
}
