#!/bin/bash
# Credit: https://gist.github.com/quietvoid/dd6a122f0c2c2d053389a99ea6238d4e

num=$(swaymsg -t get_workspaces | jq -r "map(select(.focused))[0].num")
ws_input=$(wofi --dmenu -p 'New name for this workspace: ');
active_ws=$(swaymsg -t get_workspaces | jq '.[] | select(.focused==true) | .name')

swaymsg rename workspace $active_ws to $num:$ws_input
