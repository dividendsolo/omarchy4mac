#!/usr/bin/env bash
# Update badge: how many Homebrew packages are outdated. Hidden at zero.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

COUNT="$(/opt/homebrew/bin/brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')"
if [ "${COUNT:-0}" -gt 0 ]; then
  center_item "$NAME" icon="󰚰" icon.color="$ORANGE" label="$COUNT" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
