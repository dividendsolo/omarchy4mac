#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

LABEL="$(date '+%a  %-I:%M %p')"
ICON="󰥔"

source "$CONFIG_DIR/plugins/displays.sh"

if [ "$BUILTIN" != "-" ]; then
  sketchybar --set clock_right drawing=on associated_display="$BUILTIN" \
                   icon="$ICON" icon.color="${PINK:-$MAGENTA}" label="$LABEL" label.color="$FG"
else
  sketchybar --set clock_right drawing=off
fi

if [ "$OTHERS" != "-" ]; then
  sketchybar --set clock drawing=on associated_display="$OTHERS" \
                   icon="$ICON" icon.color="${PINK:-$MAGENTA}" label="$LABEL" label.color="$FG"
else
  sketchybar --set clock drawing=off
fi
