#!/usr/bin/env bash

setup_dotfiles() {
    cp -f "${__dir}/dotfiles/.gitconfig" ~/.gitconfig
    cp -f "${__dir}/dotfiles/.zshrc" ~/.zshrc
    cp -f "${__dir}/dotfiles/.p10k.zsh" ~/.p10k.zsh
    cp -f "${__dir}/dotfiles/.nanorc" ~/.nanorc
    cp -f "${__dir}/dotfiles/.gemrc" ~/.gemrc
}
