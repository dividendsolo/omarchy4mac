#!/usr/bin/env bash
# Static Bluetooth indicator. macOS Tahoe gates Bluetooth API behind a privacy
# permission that sketchybar (as a launchd background service) can't trigger,
# so we just show the icon and rely on click-to-open-settings.
# External screens only: on the notched built-in screen the right side has no
# room for an icon that never changes (#70).
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

center_item "$NAME" \
  icon="󰂯" \
  icon.color="$BLUE" \
  label.drawing=off
