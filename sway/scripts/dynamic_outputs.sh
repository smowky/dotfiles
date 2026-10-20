#!/usr/bin/env bash

# Log helper
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> /tmp/sway_dynamic_outputs.log; }

# Function to map workspaces
map_workspaces() {
    log "Mapping workspaces..."
    
    # Wait until outputs are active
    for i in {1..10}; do
        outputs=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .name')
        if [[ -n "$outputs" ]]; then
            break
        fi
        sleep 0.5
    done

    for output in $outputs; do
        case "$output" in
            "BNQ BenQ GW2470 G6H01576019")
                for ws in 1 2 3 4 5; do
                    swaymsg "workspace $ws; move workspace to output \"$output\""
                done
                ;;
            "BNQ BenQ GW2470 6AF02336019")
                for ws in 6 7 8 9 0; do
                    swaymsg "workspace $ws; move workspace to output \"$output\""
                done
                ;;
            *)
                log "Unknown output: $output"
                ;;
        esac
    done
    log "Workspace mapping complete."
}

# Function to detect which profile to apply
apply_kanshi() {
    log "Applying Kanshi profile..."
    kanshi
    log "Kanshi applied."
}

# Main watcher loop
log "Starting dynamic output watcher..."
swaymsg -t subscribe '["output"]' | while read -r line; do
    log "Output event detected: $line"
    
    # Give Sway a moment to stabilize
    sleep 0.5

    apply_kanshi

    # Wait again to ensure outputs are active
    sleep 0.5

    map_workspaces
done
