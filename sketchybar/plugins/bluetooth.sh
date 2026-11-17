#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

center_item "$NAME" \
  icon="󰂯" \
  icon.color="$BLUE" \
  label.drawing=off
