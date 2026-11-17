#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

OUT="$(curl -s --max-time 5 'https://wttr.in/?format=%c+%t' 2>/dev/null | tr -d '\n' | sed 's/+//')"
if [ -n "$OUT" ] && [[ "$OUT" != *"Unknown"* ]] && [[ "$OUT" != *"Sorry"* ]]; then
  center_item "$NAME" label="$OUT" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
