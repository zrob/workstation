#!/usr/bin/env bash

setup_rectangle() {
    local filename="RectangleConfig.json"
    local source_prefs="${__dir}/assets/rectangle/${filename}"
    local dest_prefs_folder="${HOME}/Library/Application Support/Rectangle"

    mkdir -p "${dest_prefs_folder}"
    rm -fr "${dest_prefs_folder:?}"/*
    cp "${source_prefs}" "${dest_prefs_folder}/${filename}" >/dev/null 2>&1
}
