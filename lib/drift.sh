#!/usr/bin/env bash

# drift journal: quietly records changes made outside this repo (apps editing
# files station overwrites, upstream template changes, version bumps, brew
# caveats, new macOS defaults keys) so they can be reviewed later with bin/drift.
#
# sourced by install.sh (to record) and bin/drift (to review).
# every recording function is meant to be called as `drift_x ... || true` so a
# failed check never stops a station run.

drift_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/drift"
drift_journal="${drift_dir}/journal.tsv"
drift_reviewed_file="${drift_dir}/reviewed"

drift_init() {
    mkdir -p "${drift_dir}"/{details,seen,installed,snapshots}
    touch "$drift_journal"
}

drift_slug() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

# flatten to a single journal field
drift_clean() {
    printf '%s' "$1" | tr '\t\n' '  '
}

drift_tmp() {
    mktemp "${TMPDIR:-/tmp}/drift.XXXXXX"
}

# drift_record KIND SUBJECT MESSAGE [DETAIL_FILE]
# the detail file (if any) is moved into the journal's details dir
drift_record() {
    local kind="$1" subject="$2" message="$3" detail_src="${4:-}"
    local now detail=""

    drift_init
    now=$(date +%s)

    if [[ -n "$detail_src" && -s "$detail_src" ]]; then
        detail="details/${now}-${RANDOM}-${kind}-$(drift_slug "$subject").txt"
        mv "$detail_src" "${drift_dir}/${detail}"
    elif [[ -n "$detail_src" ]]; then
        rm -f "$detail_src"
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$now" "$kind" "$(drift_clean "$subject")" \
        "$(drift_clean "$message")" "$detail" >>"$drift_journal"
}

# drift_is_new KEY VALUE
# true (and remembers VALUE) when VALUE differs from the last one seen for KEY.
# used to record a repeating change once instead of on every run.
drift_is_new() {
    local file
    drift_init
    file="${drift_dir}/seen/$(drift_slug "$1")"
    [[ -f "$file" && "$(cat "$file")" == "$2" ]] && return 1
    printf '%s\n' "$2" >"$file"
}

###
# files station overwrites
###

# drift_install_file REPO_FILE LIVE_FILE [LABEL]
# copies REPO_FILE over LIVE_FILE, first recording anything that changed LIVE_FILE
# since station last installed it. comparing against the last installed copy (not
# the current repo file) keeps your own repo edits from showing up as drift.
drift_install_file() {
    local repo="$1" live="$2" label="${3:-$(basename "$2")}"

    drift_check_file "$repo" "$live" "$label" || true
    cp -f "$repo" "$live"
    drift_init
    cp -f "$repo" "${drift_dir}/installed/$(drift_slug "$label")"
}

# drift_matches_history REPO_FILE LIVE_FILE
# true when LIVE_FILE is byte-identical to some committed version of REPO_FILE
drift_matches_history() {
    local repo="$1" live="$2" dir blob blobs

    dir=$(dirname "$repo")
    git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || return 1
    blob=$(git -C "$dir" hash-object "$live")

    # every blob the file has had, from the raw diff lines (":mode mode old new status path")
    blobs=$(git -C "$dir" log --all --format= --raw --no-abbrev -- "$(basename "$repo")" | awk '{print $4}')
    grep -qx "$blob" <<<"$blobs"
}

drift_check_file() {
    local repo="$1" live="$2" label="$3"
    local baseline saved tmp added removed

    [[ -f "$live" ]] || return 0
    drift_init

    baseline="${drift_dir}/installed/$(drift_slug "$label")"
    # first run on this machine: nothing installed yet to compare to. a live file
    # matching any committed version of the repo file is just an older install.
    if [[ ! -f "$baseline" ]]; then
        drift_matches_history "$repo" "$live" && return 0
        baseline="$repo"
    fi

    cmp -s "$baseline" "$live" && return 0
    drift_is_new "file-${label}" "$(cksum <"$live")" || return 0

    saved="${drift_dir}/details/$(date +%s)-${RANDOM}-$(drift_slug "$label").live"
    cp "$live" "$saved"

    tmp=$(drift_tmp)
    {
        echo "# ${live} was changed outside the repo (diff: last installed -> live)"
        echo "# saved copy: ${saved}"
        echo "# compare:    git diff --no-index ${repo} ${saved}"
        echo
        diff -u "$baseline" "$live" || true
    } >"$tmp"

    added=$(grep -c '^+[^+]' "$tmp" || true)
    removed=$(grep -c '^-[^-]' "$tmp" || true)
    drift_record drift "$label" "${live/#$HOME/~} changed outside the repo (+${added} -${removed} lines)" "$tmp"
}

###
# plist keys
###

# drift_plist_keys DOMAIN [currentHost]
# top-level keys of a defaults domain, one per line, sorted
drift_plist_keys() {
    local -a host=()
    [[ "${2:-}" == currentHost ]] && host=(-currentHost)

    defaults ${host[@]+"${host[@]}"} read "$1" 2>/dev/null |
        awk '/^    [^ ]/ && / = / { sub(/^    /, ""); sub(/ = .*/, ""); gsub(/^"|"$/, ""); print }' |
        sort -u
}

# keys that churn on their own and say nothing about settings
drift_noise_keys='^(NSWindow Frame|NSNav|NSStatusItem|NSSplitView|NSTableView|NSToolbar|SU|AK|lastShowIndicatorTime|last-analytics-stamp|mod-count)'

# Rectangle: settings it has stored that RectangleConfig.json doesn't mention
drift_check_rectangle() {
    local config="$1" folder="$2"
    local live repo new tmp extra key

    if [[ -d "$folder" ]]; then
        extra=$(cd "$folder" && ls -A | grep -vx "$(basename "$config")" || true)
        if [[ -n "$extra" ]] && drift_is_new "rectangle-files" "$extra"; then
            drift_record drift Rectangle "unexpected files in ${folder/#$HOME/~} (deleted by station): $(tr '\n' ' ' <<<"$extra")"
        fi
    fi

    live=$(drift_plist_keys com.knollsoft.Rectangle |
        grep -Ev "$drift_noise_keys" |
        grep -Ev '^(lastVersion|wasWelcomeDisplayed|internalTilingNotified)$' || true)
    repo=$(jq -r '(.defaults // {} | keys[]), (.shortcuts // {} | keys[])' "$config" | sort -u)
    new=$(comm -23 <(printf '%s\n' "$live") <(printf '%s\n' "$repo") | sed '/^$/d')

    [[ -n "$new" ]] || return 0
    drift_is_new "rectangle-keys" "$new" || return 0

    tmp=$(drift_tmp)
    {
        echo "# Rectangle has these settings, but RectangleConfig.json doesn't."
        echo "# to keep them: Rectangle > Settings > Export, then copy into ${config}"
        echo
        while read -r key; do
            echo "${key} = $(defaults read com.knollsoft.Rectangle "$key" 2>/dev/null | tr '\n' ' ')"
        done <<<"$new"
    } >"$tmp"

    drift_record drift Rectangle "$(wc -l <<<"$new" | tr -d ' ') setting(s) not in RectangleConfig.json: $(tr '\n' ' ' <<<"$new")" "$tmp"
}

###
# upstream
###

# drift_record_upstream SUBJECT REPO_DIR OLD_REV NEW_REV PATHSPEC...
# saves the commits between two revs that touched PATHSPEC
drift_record_upstream() {
    local subject="$1" dir="$2" old="$3" new="$4"
    shift 4
    local tmp count

    [[ -n "$old" && -n "$new" && "$old" != "$new" ]] || return 0

    tmp=$(drift_tmp)
    git -C "$dir" log -p --no-color --date=short \
        --format='commit %h  %ad  %s' "${old}..${new}" -- "$@" >"$tmp" 2>/dev/null || true

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        return 0
    fi

    count=$(git -C "$dir" rev-list --count "${old}..${new}" -- "$@")
    drift_record upstream "$subject" "${old:0:7}..${new:0:7}: ${count} commit(s) touching $*" "$tmp"
}

# drift_read_base FILE
# prints "COMMIT DATE" from the first line that isn't a comment
drift_read_base() {
    awk '!/^[[:space:]]*(#|$)/ { print $1, $2; exit }' "$1" 2>/dev/null
}

# what shapes the lean config `p10k configure` writes: the template, and the wizard's edits to it
drift_p10k_paths=(config/p10k-lean.zsh internal/wizard.zsh)

# drift_check_p10k P10K_DIR BASE_FILE
# records p10k template and wizard changes after the commit .p10k.zsh was last merged with.
# picks up where the last recorded entry stopped, so each change is recorded once, and starts
# from the base on a new machine, where the journal is empty.
drift_check_p10k() {
    local dir="$1" base_file="$2"
    local base date head last from

    read -r base date <<<"$(drift_read_base "$base_file")"
    [[ -n "$base" ]] || return 0
    head=$(git -C "$dir" rev-parse HEAD 2>/dev/null) || return 0
    [[ "$head" != "$base" ]] || return 0

    # station clones p10k with --depth=1, so the base may not be fetched yet
    if ! git -C "$dir" cat-file -e "${base}^{commit}" 2>/dev/null; then
        [[ -n "$date" ]] && git -C "$dir" fetch -q --shallow-since="${date} 00:00:00" 2>/dev/null
        git -C "$dir" cat-file -e "${base}^{commit}" 2>/dev/null ||
            git -C "$dir" fetch -q --unshallow 2>/dev/null
        git -C "$dir" cat-file -e "${base}^{commit}" 2>/dev/null || return 0
    fi

    drift_init
    last=$(cat "${drift_dir}/seen/p10k-recorded" 2>/dev/null || true)
    from="$base"
    # continue from the last recorded commit, unless a newer merge moved the base past it
    if [[ -n "$last" ]] && git -C "$dir" merge-base --is-ancestor "$base" "$last" 2>/dev/null; then
        from="$last"
    fi
    [[ "$from" != "$head" ]] || return 0

    drift_record_upstream Powerlevel10k "$dir" "$from" "$head" "${drift_p10k_paths[@]}"
    echo "$head" >"${drift_dir}/seen/p10k-recorded"
}

###
# iTerm
###

# drift_check_iterm_profile REPO_PLIST
# settings iTerm's built-in default profile has that your profiles don't. iTerm only stores
# what a profile sets, so new keys here are usually features added since the profile was made.
drift_check_iterm_profile() {
    local plist="$1"
    local defaults_plist="/Applications/iTerm.app/Contents/Resources/DefaultBookmark.plist"
    local defaults_json missing count names tmp

    [[ -f "$plist" && -f "$defaults_plist" ]] || return 0

    defaults_json=$(plutil -convert json -o - "$defaults_plist" 2>/dev/null) || return 0

    # "profile<TAB>key<TAB>default value" for each key a profile is missing
    missing=$(plutil -extract "New Bookmarks" json -o - "$plist" 2>/dev/null |
        jq -r --argjson d "$defaults_json" '
            .[] as $p | ($d | keys) - ($p | keys) | .[] |
            [($p.Name // "unnamed"), ., ($d[.] | tojson)] | @tsv') || return 0

    [[ -n "$missing" ]] || return 0
    drift_is_new "iterm-profile-keys" "$(cut -f1,2 <<<"$missing" | cksum)" || return 0

    count=$(wc -l <<<"$missing" | tr -d ' ')
    names=$(cut -f2 <<<"$missing" | head -6 | paste -sd, - | sed 's/,/, /g')
    ((count > 6)) && names+=", ..."

    tmp=$(drift_tmp)
    {
        echo "# settings in iTerm's default profile that your profiles don't set, with iTerm's default."
        echo "# usually features added after your profile was made. set them in Settings > Profiles,"
        echo "# then save iTerm's settings to: ${plist}"
        echo
        printf '%s\n' "$missing" | awk -F'\t' '{ printf "%s: %s = %s\n", $1, $2, $3 }'
    } >"$tmp"

    drift_record upstream "iTerm2 profile" "${count} setting(s) your profile doesn't set: ${names}" "$tmp"
}

###
# versions
###

# drift_check_version NAME VERSION [NOTES_URL]
# first sighting is stored silently; later changes are recorded
drift_check_version() {
    local name="$1" version="$2" url="${3:-}"
    local file old

    [[ -n "$version" ]] || return 0
    drift_init

    file="${drift_dir}/seen/version-$(drift_slug "$name")"
    old=$(cat "$file" 2>/dev/null || true)
    printf '%s\n' "$version" >"$file"

    [[ -n "$old" && "$old" != "$version" ]] || return 0
    drift_record version "$name" "${old} -> ${version}${url:+  notes: ${url}}"
}

drift_app_version() {
    defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null || true
}

drift_check_versions() {
    drift_check_version git "$(git --version 2>/dev/null | awk '{print $3}')" \
        "https://github.com/git/git/tree/master/Documentation/RelNotes"
    drift_check_version zsh "$(zsh --version 2>/dev/null | awk '{print $2}')" \
        "https://zsh.sourceforge.io/releases.html"

    if [[ "$(uname)" == Darwin ]]; then
        drift_check_version macOS "$(sw_vers -productVersion)" \
            "https://developer.apple.com/documentation/macos-release-notes"
        drift_check_version iTerm2 "$(drift_app_version /Applications/iTerm.app)" \
            "https://iterm2.com/downloads.html"
        drift_check_version Rectangle "$(drift_app_version /Applications/Rectangle.app)" \
            "https://github.com/rxhanson/Rectangle/releases"
    fi
}

###
# macOS defaults
###

# for every domain station manages, record keys that appeared or disappeared since
# the last run. the first run on a machine only takes the snapshot.
drift_check_defaults() {
    local file="$1"
    local domain flags snapshot current added removed tmp key
    local -a host

    drift_init

    awk '!/^[[:space:]]*(#|$)/ { print $1, ($5 == "currentHost" ? "currentHost" : "") }' "$file" | sort -u |
        while read -r domain flags; do
            host=()
            [[ "$flags" == currentHost ]] && host=(-currentHost)

            snapshot="${drift_dir}/snapshots/$(drift_slug "${domain}${flags:+-$flags}")"
            current=$(drift_plist_keys "$domain" "$flags" | grep -Ev "$drift_noise_keys" || true)

            if [[ ! -f "$snapshot" ]]; then
                printf '%s\n' "$current" >"$snapshot"
                continue
            fi

            added=$(comm -13 "$snapshot" <(printf '%s\n' "$current") | sed '/^$/d')
            removed=$(comm -23 "$snapshot" <(printf '%s\n' "$current") | sed '/^$/d')
            printf '%s\n' "$current" >"$snapshot"

            [[ -n "$added$removed" ]] || continue

            tmp=$(drift_tmp)
            {
                echo "# keys that appeared or disappeared in: defaults ${host[*]:-}read ${domain}"
                echo
                while read -r key; do
                    [[ -n "$key" ]] || continue
                    echo "+ ${key} = $(defaults ${host[@]+"${host[@]}"} read "$domain" "$key" 2>/dev/null | tr '\n' ' ')"
                done <<<"$added"
                while read -r key; do
                    [[ -n "$key" ]] && echo "- ${key}"
                done <<<"$removed"
            } >"$tmp"

            drift_record defaults "${domain}${flags:+ ($flags)}" \
                "new keys: $(tr '\n' ' ' <<<"${added:-none}") removed: $(tr '\n' ' ' <<<"${removed:-none}")" "$tmp"
        done
}

###
# homebrew
###

drift_brew_versions() {
    { brew list --formula --versions; brew list --cask --versions; } 2>/dev/null | sort
}

# drift_check_brew_upgrades BEFORE_FILE
# records caveats of anything installed or upgraded since BEFORE_FILE was taken
drift_check_brew_upgrades() {
    local before="$1"
    local changed name caveats tmp

    changed=$(comm -13 "$before" <(drift_brew_versions) | awk '{print $1}')
    [[ -n "$changed" ]] || return 0

    while read -r name; do
        caveats=$(brew info --json=v2 "$name" 2>/dev/null |
            jq -r '(.formulae + .casks)[] | .caveats // empty' || true)
        [[ -n "$caveats" ]] || continue
        drift_is_new "caveats-${name}" "$(cksum <<<"$caveats")" || continue

        tmp=$(drift_tmp)
        printf '%s\n' "$caveats" >"$tmp"
        drift_record caveats "$name" "brew caveats for ${name} $(brew list --versions "$name" 2>/dev/null | awk '{print $NF}')" "$tmp"
    done <<<"$changed"
}

# things you installed on purpose that the Brewfile doesn't list
drift_check_brew_untracked() {
    local brewfile="$1"
    local would requested untracked tmp

    # the "Would uninstall" headers go to stderr, the names to stdout
    would=$(brew bundle cleanup --file="$brewfile" 2>&1 |
        awk '/^Would uninstall (casks|formulae):/ { on = 1; next } /^Would|^Run / { on = 0 } on' | sort -u || true)
    [[ -n "$would" ]] || return 0

    # only top-level formulae you asked for, not their dependencies
    requested=$({ brew leaves --installed-on-request; brew list --cask; } 2>/dev/null | sort -u)
    untracked=$(comm -12 <(printf '%s\n' "$would") <(printf '%s\n' "$requested"))

    [[ -n "$untracked" ]] || return 0
    drift_is_new "brew-untracked" "$untracked" || return 0

    tmp=$(drift_tmp)
    {
        echo "# installed but not in the Brewfile. add them, or remove with: brew bundle cleanup --force"
        echo
        printf '%s\n' "$untracked"
    } >"$tmp"
    drift_record drift Brewfile "$(wc -l <<<"$untracked" | tr -d ' ') installed package(s) not in the Brewfile: $(tr '\n' ' ' <<<"$untracked")" "$tmp"
}

###
# reading the journal
###

# the reviewed file holds "<newest entry marked done> <when drift done ran>"
# drift_reviewed_at [done]: the first field, or the second with "done"
drift_reviewed_at() {
    local marked="" done_at=""
    { read -r marked done_at <"$drift_reviewed_file"; } 2>/dev/null || true
    [[ "${1:-}" == done ]] && marked="${done_at:-$marked}"
    [[ "$marked" =~ ^[0-9]+$ ]] && echo "$marked" || echo 0
}

# journal lines recorded after the last review
drift_pending() {
    [[ -f "$drift_journal" ]] || return 0
    awk -F'\t' -v since="$(drift_reviewed_at)" '$1 > since' "$drift_journal"
}

# one line when the oldest unreviewed change is older than the limit, otherwise nothing
drift_nag() {
    local max_days="${WORKSTATION_DRIFT_MAX_DAYS:-60}"
    local pending oldest days count apps

    pending=$(drift_pending)
    [[ -n "$pending" ]] || return 0

    oldest=$(cut -f1 <<<"$pending" | sort -n | head -1)
    days=$((($(date +%s) - oldest) / 86400))
    ((days >= max_days)) || return 0

    count=$(wc -l <<<"$pending" | tr -d ' ')
    apps=$(cut -f3 <<<"$pending" | sort -u | wc -l | tr -d ' ')
    echo "${count} unreviewed changes across ${apps} apps since $(date -r "$oldest" +%F 2>/dev/null || date -d "@$oldest" +%F). Run: drift review"
}
