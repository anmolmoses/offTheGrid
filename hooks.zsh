#!/usr/bin/env zsh
# hooks.zsh — Off The Grid shell integration
# Sourced in .zshrc to intercept blocked app commands.
#
# How it works:
#   1. For each app in ~/.offthegrid/apps/, a zsh function is created
#      with the same name (e.g. "claude").
#   2. When you type that command, the function runs instead.
#   3. It checks the master switch + schedule to decide: block or allow.
#   4. If blocked, it calls `otg _blocked <app>` to show the denied screen.
#   5. If allowed, it falls through to `command <app>` (the real binary).

_OTG_DIR="$HOME/.offthegrid"
_OTG_ROOT="${0:A:h}"          # resolve to directory containing this script
_OTG_BIN="$_OTG_ROOT/otg"
_OTG_BLOCKED_APPS=()

# ─── Time Utilities ──────────────────────────────

_otg_time_to_min() {
    local t="$1"
    echo $(( 10#${t%%:*} * 60 + 10#${t##*:} ))
}

_otg_day_match() {
    local days="$1"
    local today
    today=$(date +%a | tr '[:upper:]' '[:lower:]')

    case "$days" in
        all)
            return 0
            ;;
        weekdays)
            case "$today" in
                mon|tue|wed|thu|fri) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        weekends)
            case "$today" in
                sat|sun) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *)
            # Comma-separated day list: mon,wed,fri
            [[ ",$days," == *",$today,"* ]] && return 0
            return 1
            ;;
    esac
}

# ─── Block Check ─────────────────────────────────

# Returns 0 (true) if the app is currently blocked.
# Sets _OTG_UNTIL to the schedule end time, or "" for always-on blocks.
_otg_is_blocked() {
    local app="$1"
    _OTG_UNTIL=""

    # Master switch must be on
    [[ -f "$_OTG_DIR/state" ]] || return 1
    [[ "$(< "$_OTG_DIR/state")" == "on" ]] || return 1

    # App must be in the blocklist
    local app_file="$_OTG_DIR/apps/$app"
    [[ -f "$app_file" ]] || return 1

    local sched
    sched="$(< "$app_file")"

    # "always" means blocked whenever the master switch is on
    [[ "$sched" == "always" ]] && return 0

    # Check each schedule line (supports multiple rules per app)
    local line
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue

        local range="${line%% *}"
        local days="${line##* }"
        [[ "$days" == "$range" ]] && days="all"

        # Day check
        _otg_day_match "$days" || continue

        # Time check
        local s_time="${range%%-*}"
        local e_time="${range##*-}"
        local now=$(_otg_time_to_min "$(date +%H:%M)")
        local s=$(_otg_time_to_min "$s_time")
        local e=$(_otg_time_to_min "$e_time")

        if (( s <= e )); then
            # Normal range, e.g. 09:00-17:00
            if (( now >= s && now < e )); then
                _OTG_UNTIL="$e_time"
                return 0
            fi
        else
            # Crosses midnight, e.g. 22:00-06:00
            if (( now >= s || now < e )); then
                _OTG_UNTIL="$e_time"
                return 0
            fi
        fi
    done <<< "$sched"

    return 1
}

# ─── Hook Management ─────────────────────────────

# Rebuild all interceptor functions from the current config.
# Called on shell startup and after any otg config change.
_otg_refresh() {
    # Tear down previous interceptors
    local a
    for a in "${_OTG_BLOCKED_APPS[@]}"; do
        unfunction "$a" 2>/dev/null || true
    done
    _OTG_BLOCKED_APPS=()

    # Only set up interceptors when the master switch is on
    [[ -f "$_OTG_DIR/state" && "$(< "$_OTG_DIR/state")" == "on" ]] || return 0
    [[ -d "$_OTG_DIR/apps" ]] || return 0

    local f
    for f in "$_OTG_DIR/apps"/*(.N); do
        local name="${f:t}"
        _OTG_BLOCKED_APPS+=("$name")

        # Remove any alias that might shadow our function
        unalias "$name" 2>/dev/null || true

        # Create the interceptor function
        eval "
            ${name}() {
                if _otg_is_blocked '${name}'; then
                    command \"\$_OTG_BIN\" _blocked '${name}' \"\$_OTG_UNTIL\"
                    return 1
                else
                    command ${name} \"\$@\"
                fi
            }
        "
    done
}

# ─── OTG Command Wrapper ─────────────────────────

# Wraps the otg script so we can refresh hooks in the current shell
# after any command that changes blocking state.
otg() {
    command "$_OTG_BIN" "$@"
    local ret=$?

    case "${1:-}" in
        add|remove|rm|on|off|install|schedule|sched)
            _otg_refresh
            ;;
    esac

    return $ret
}

# ─── Init ────────────────────────────────────────

_otg_refresh
