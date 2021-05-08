#!/usr/bin/env bash

print_setup_list() {
    local header="$1"
    local -a list=("${!2:-none}")
    local indent="    "

    echo "$header"

    for item in "${list[@]}"; do
        # display item with indent and remove 'setup_' prefix
        echo "${indent}${item#"setup_"}";
    done
}