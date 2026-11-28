#!/usr/bin/env bash

setup_rectangle() {
    if [[ "$(uname)" != Darwin ]]; then
        echo "Skipping rectangle...not macOS"
        return
    fi

    local filename="RectangleConfig.json"
    local source_prefs="${__dir}/assets/rectangle/${filename}"
    local dest_prefs_folder="${HOME}/Library/Application Support/Rectangle"

    drift_check_rectangle "${source_prefs}" "${dest_prefs_folder}" || true

    mkdir -p "${dest_prefs_folder}"
    rm -fr "${dest_prefs_folder:?}"/*
    cp "${source_prefs}" "${dest_prefs_folder}/${filename}" >/dev/null 2>&1
}
