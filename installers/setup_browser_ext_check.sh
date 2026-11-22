#!/usr/bin/env bash

# one line on how long ago the firefox extension backups were last confirmed
# current by bin/browser-ext (a backup, or a diff that matched)

setup_browser_ext_check() {
    if [[ "$(uname)" != Darwin ]]; then
        echo "Skipping browser ext check...not macOS"
        return
    fi

    local state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/browser-ext"
    local max_days="${WORKSTATION_BROWSER_EXT_MAX_DAYS:-30}"
    local backups="assets/browser-extension-config/firefox"
    local now oldest="" stale="" ext file ts days

    now=$(date +%s)

    for ext in ublock cad tampermonkey; do
        case "$ext" in
            ublock) file=ublock.json ;;
            cad) file=cad-expressions.json ;;
            tampermonkey) file=tampermonkey.txt ;;
        esac

        ts=$(cat "${state_dir}/${ext}" 2>/dev/null || true)
        if [[ ! "$ts" =~ ^[0-9]+$ ]]; then
            # never checked on this machine: fall back to when the backup was committed
            ts=$(git -C "$__dir" log -1 --format=%ct -- "${backups}/${file}" 2>/dev/null || true)
        fi
        [[ "$ts" =~ ^[0-9]+$ ]] || continue

        days=$(((now - ts) / 86400))
        if ((days > max_days)); then
            stale+=" ${ext}"
        fi
        if [[ -z "$oldest" ]] || ((ts < oldest)); then
            oldest="$ts"
        fi
    done

    if [[ -z "$oldest" ]]; then
        echo "Browser extension backups: none yet (run: browser-ext backup all)"
        return
    fi

    days=$(((now - oldest) / 86400))
    if [[ -n "$stale" ]]; then
        echo "Browser extension backups last confirmed ${days} days ago (${stale# }). Run: browser-ext diff all"
    elif ((days == 0)); then
        echo "Browser extension backups confirmed today"
    else
        echo "Browser extension backups confirmed ${days} day(s) ago"
    fi
}
