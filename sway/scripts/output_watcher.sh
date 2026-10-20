#!/usr/bin/env bash

#!/usr/bin/env bash

# Continuously listen for Sway output events
swaymsg -t subscribe '["output"]' | while read -r line; do
    echo "Output event detected: $line"

    # Give Sway a moment to stabilize output changes
    sleep 1

    # Apply the correct Kanshi profile
    kanshi

    # Wait a bit more to ensure outputs are active
    sleep 1

    # Map workspaces to the newly active outputs
    ~/.config/sway/scripts/map_workspaces.sh
done
