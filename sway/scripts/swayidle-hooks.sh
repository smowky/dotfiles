#!/bin/bash
exec swayidle -w \
	before-sleep "swaymsg 'output * dpms on' && sleep 3 && gtklock -d"
