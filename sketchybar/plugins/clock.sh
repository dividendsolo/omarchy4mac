#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

LABEL="$(date '+%a  %-I:%M %p')"
ICON="󰥔"
THEME="$(cat "$HOME/.config/theme-switcher/current" 2>/dev/null || echo "?")"

source "$CONFIG_DIR/plugins/displays.sh"

if [ "$BUILTIN" != "-" ]; then
  sketchybar --set clock_right drawing=on associated_display="$BUILTIN" \
                   icon="$ICON" icon.color="$MAGENTA" label="$LABEL" label.color="$FG" \
             --set theme_name_right drawing=on associated_display="$BUILTIN" \
                   label="$THEME" label.color="$FG"
else
  sketchybar --set clock_right drawing=off --set theme_name_right drawing=off
fi

if [ "$OTHERS" != "-" ]; then
  sketchybar --set clock drawing=on associated_display="$OTHERS" \
                   icon="$ICON" icon.color="$MAGENTA" label="$LABEL" label.color="$FG" \
             --set theme_name drawing=on associated_display="$OTHERS" \
                   label="$THEME" label.color="$FG"
else
  sketchybar --set clock drawing=off --set theme_name drawing=off
fi
