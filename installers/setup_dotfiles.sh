#!/usr/bin/env bash

# drift_install_file records anything that changed the live file before overwriting it
setup_dotfiles() {
    drift_install_file "${__dir}/dotfiles/.gitconfig" ~/.gitconfig
    drift_install_file "${__dir}/dotfiles/.zshrc" ~/.zshrc
    drift_install_file "${__dir}/dotfiles/.p10k.zsh" ~/.p10k.zsh
    drift_install_file "${__dir}/dotfiles/.nanorc" ~/.nanorc
    drift_install_file "${__dir}/dotfiles/.gemrc" ~/.gemrc
}
