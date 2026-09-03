#!/usr/bin/env bash
# Weather from wttr.in for the current location (IP-based). Hidden offline.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

OUT="$(curl -s --max-time 5 'wttr.in/?format=%c+%t' 2>/dev/null | tr -d '\n' | sed 's/+//')"
if [ -n "$OUT" ] && [[ "$OUT" != *"Unknown"* ]] && [[ "$OUT" != *"Sorry"* ]]; then
  center_item "$NAME" label="$OUT" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
