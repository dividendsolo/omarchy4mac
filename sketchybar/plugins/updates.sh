#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

OUTDATED="$(/opt/homebrew/bin/brew outdated --quiet 2>/dev/null)" || exit 0
COUNT="$(printf '%s' "$OUTDATED" | grep -c .)"
if [ "${COUNT:-0}" -gt 0 ]; then
  center_item "$NAME" icon="󰚰" icon.color="$ORANGE" label="$COUNT" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
