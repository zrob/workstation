#!/usr/bin/env bash

if ! command -v brew &> /dev/null
then
    echo "'brew' could not be found. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install


