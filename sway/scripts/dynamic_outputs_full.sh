#!/usr/bin/env bash
# ==========================
# Bulletproof Dynamic Output Watcher for Sway
# ==========================

LOGFILE="/tmp/sway_dynamic_outputs_full.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGFILE"
}

log "Starting bulletproof dynamic output watcher..."

# EDID / Monitor identifiers
LAPTOP_EDID="eDP-1"
EXT1_EDID="BNQ BenQ GW2470 G6H01576019"
EXT2_EDID="BNQ BenQ GW2470 6AF02336019"

# Workspace assignments
declare -A WORKSPACES
WORKSPACES["$EXT1_EDID"]="1 2 3 4 5"
WORKSPACES["$EXT2_EDID"]="6 7 8 9 0"
WORKSPACES["$LAPTOP_EDID"]="10 11 12"

# Store last applied profile to avoid reapplying
LAST_PROFILE=""

# Wait until outputs stabilize
wait_for_active_outputs() {
    local active=""
    for i in {1..10}; do
        active=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | "\(.name) \(.make) \(.model)"')
        [[ -n "$active" ]] && break
        sleep 0.5
    done
    echo "$active"
}

# Map EDID -> Sway output names
get_edid_map() {
    declare -A edid_map
    while read -r sway make model; do
        full="$make $model"
        [[ "$full" == "$EXT1_EDID"* ]] && edid_map["$EXT1_EDID"]="$sway"
        [[ "$full" == "$EXT2_EDID"* ]] && edid_map["$EXT2_EDID"]="$sway"
        [[ "$sway" == "$LAPTOP_EDID" ]] && edid_map["$LAPTOP_EDID"]="$sway"
    done <<< "$1"
    echo "${edid_map[@]}"
}

# Determine profile to apply
determine_profile() {
    declare -n map=$1
    local profile=""
    if [[ -n "${map[$EXT1_EDID]}" && -n "${map[$EXT2_EDID]}" ]]; then
        profile="home_3_monitors"
    elif [[ -n "${map[$EXT1_EDID]}" || -n "${map[$EXT2_EDID]}" ]]; then
        profile="home_2_monitors"
    else
        profile="laptop_only"
    fi
    echo "$profile"
}

# Apply Kanshi profile only if changed
apply_profile() {
    local profile="$1"
    [[ "$profile" == "$LAST_PROFILE" ]] && return
    log "Applying profile: $profile"
    kanshi profile "$profile"
    LAST_PROFILE="$profile"
}

# Map workspaces to Sway outputs
map_workspaces() {
    declare -n edid_map=$1
    for edid in "${!WORKSPACES[@]}"; do
        sway_out="${edid_map[$edid]}"
        [[ -z "$sway_out" ]] && continue
        for ws in ${WORKSPACES[$edid]}; do
            swaymsg "workspace $ws; move workspace to output \"$sway_out\""
            log "Moved workspace $ws -> $sway_out"
        done
    done
}

# Main loop: listen for output events
swaymsg -t subscribe '["output"]' | while read -r line; do
    log "Output event detected: $line"
    sleep 1  # wait for outputs to settle

    active_info=$(wait_for_active_outputs)
    declare -A EDID_MAP
    while read -r sway make model; do
        full="$make $model"
        [[ "$full" == "$EXT1_EDID"* ]] && EDID_MAP["$EXT1_EDID"]="$sway"
        [[ "$full" == "$EXT2_EDID"* ]] && EDID_MAP["$EXT2_EDID"]="$sway"
        [[ "$sway" == "$LAPTOP_EDID" ]] && EDID_MAP["$LAPTOP_EDID"]="$sway"
    done <<< "$active_info"

    PROFILE=$(determine_profile EDID_MAP)
    apply_profile "$PROFILE"
    sleep 1  # wait for profile to apply
    map_workspaces EDID_MAP
done
