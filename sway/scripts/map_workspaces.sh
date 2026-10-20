#!/usr/bin/env bash

# Wait until at least 1 external monitor is active
for i in {1..10}; do
    outputs=$(swaymsg -t get_outputs | jq -r '.[] | select(.active and .name != "eDP-1") | .name')
    if [[ -n "$outputs" ]]; then
        break
    fi
    sleep 0.5
done

# Define your monitors and workspaces
LEFT_MONITOR=$(echo "$outputs" | head -n 1)
RIGHT_MONITOR=$(echo "$outputs" | tail -n 1)

# DO a replacement in sway config
sed -i "s|^\([[:space:]]*set \$SWAY_RIGHT_OUTPUT[[:space:]]\+\).*|\1${RIGHT_MONITOR}|" ~/.config/sway/config.d/environments

sed -i "s|^\([[:space:]]*set \$SWAY_LEFT_OUTPUT[[:space:]]\+\).*|\1${LEFT_MONITOR}|" ~/.config/sway/config.d/environments
# Ensure initial state: workspace 1 on left, workspace 6 on right
swaymsg "workspace 1; move workspace to output $LEFT_MONITOR"
swaymsg "workspace 6; move workspace to output $RIGHT_MONITOR"

# Map the rest of the workspaces
for ws in 2 3 4 5; do
    swaymsg "workspace $ws; move workspace to output $LEFT_MONITOR"
done
for ws in 7 8 9 0; do
    swaymsg "workspace $ws; move workspace to output $RIGHT_MONITOR"
done

# reload in the end
swaymsg reload
