#!/usr/bin/env bash

# applies the settings listed in assets/macos/defaults.txt
# only writes keys whose type or value differ, and only restarts what changed

macos_defaults_changed=0
macos_defaults_restart=""
macos_defaults_logout=false

# normalize a value for comparison: bools to 1/0, numbers to canonical form
macos_default_normalize() {
    local type="$1" value="$2"
    case "$type" in
        bool)
            case "$value" in
                1 | true | TRUE | yes | YES) echo 1 ;;
                *) echo 0 ;;
            esac
            ;;
        int | float) awk -v v="$value" 'BEGIN { printf "%.6f\n", v + 0 }' ;;
        *) echo "$value" ;;
    esac
}

macos_default_mark() {
    local domain="$1"
    local app=""

    macos_defaults_changed=$((macos_defaults_changed + 1))

    case "$domain" in
        com.apple.dock) app=Dock ;;
        com.apple.finder | com.apple.desktopservices) app=Finder ;;
        com.apple.menuextra.clock | com.apple.Siri) app=ControlCenter ;;
        com.apple.symbolichotkeys) app=activateSettings ;;
        *) macos_defaults_logout=true ;;
    esac

    if [[ -n "$app" && " $macos_defaults_restart " != *" $app "* ]]; then
        macos_defaults_restart+=" $app"
    fi
}

macos_default_ensure() {
    local domain="$1" key="$2" type="$3" value="$4" flags="${5:-}"
    local -a host=()
    [[ "$flags" == currentHost ]] && host=(-currentHost)

    if [[ "$type" == dict-add ]]; then
        local parent="${key%%:*}" entry="${key#*:}"
        local current want

        current=$(defaults ${host[@]+"${host[@]}"} export "$domain" - 2>/dev/null |
            plutil -extract "${parent}.${entry}" json -o - - 2>/dev/null |
            jq -S -c . 2>/dev/null) || current=""
        want=$(jq -S -c . <<<"$value")

        [[ "$current" == "$want" ]] && return

        defaults ${host[@]+"${host[@]}"} write "$domain" "$parent" -dict-add "$entry" \
            "$(plutil -convert xml1 -o - - <<<"$value")"
        echo "changed: ${domain} ${key} ${current:-<unset>} -> ${want}"
        macos_default_mark "$domain"
        return
    fi

    local flag read_type
    case "$type" in
        bool) flag=-bool read_type=boolean ;;
        int) flag=-int read_type=integer ;;
        float) flag=-float read_type=float ;;
        string) flag=-string read_type=string ;;
        *)
            echo "skipping ${domain} ${key}: unknown type '${type}'"
            return
            ;;
    esac

    # allow $HOME in string values
    value="${value//\$HOME/$HOME}"

    local current_type current
    current_type=$(defaults ${host[@]+"${host[@]}"} read-type "$domain" "$key" 2>/dev/null | sed 's/^Type is //') || current_type=""
    current=$(defaults ${host[@]+"${host[@]}"} read "$domain" "$key" 2>/dev/null) || current=""

    if [[ "$current_type" == "$read_type" ]] &&
        [[ "$(macos_default_normalize "$type" "$current")" == "$(macos_default_normalize "$type" "$value")" ]]; then
        return
    fi

    defaults ${host[@]+"${host[@]}"} write "$domain" "$key" "$flag" "$value"
    echo "changed: ${domain} ${key} ${current:-<unset>} -> ${value}"
    macos_default_mark "$domain"
}

setup_macos_defaults() {
    if [[ "$(uname)" != Darwin ]]; then
        echo "Skipping macos defaults...not macOS"
        return
    fi

    local file="${__dir}/assets/macos/defaults.txt"
    local domain key type value flags app

    macos_defaults_changed=0
    macos_defaults_restart=""
    macos_defaults_logout=false

    while read -r domain key type value flags; do
        [[ -z "$domain" || "$domain" == \#* ]] && continue
        macos_default_ensure "$domain" "$key" "$type" "$value" "$flags"
    done <"$file"

    for app in $macos_defaults_restart; do
        if [[ "$app" == activateSettings ]]; then
            /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
        else
            killall "$app" >/dev/null 2>&1 || true
        fi
    done

    echo "macos defaults: ${macos_defaults_changed} changed"
    if [[ "$macos_defaults_logout" == true ]]; then
        echo "log out and back in for keyboard/trackpad/global changes to fully apply"
    fi
}
