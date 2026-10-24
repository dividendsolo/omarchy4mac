#!/usr/bin/env bash
# Highlight the focused AeroSpace workspace.
# Workspace id is derived from $NAME (e.g. "space.3" → "3").
# $FOCUSED_WORKSPACE is set by the aerospace_workspace_change trigger.

source "$CONFIG_DIR/colors.sh"

SID="${NAME#space.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null)}"

# Ctrl+Left/Right switches native macOS Spaces, which AeroSpace never reports.
# space_change carries the new Space number in $INFO ({"display-1": 2}, per display).
if [ "$SENDER" = "space_change" ]; then
  FOCUSED="$(printf '%s' "$INFO" | sed -n 's/.*"display-[0-9]*"[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -1)"
fi

if [ "$SID" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$ACCENT" \
    icon.color="$BG" \
    icon.shadow.drawing=on \
    icon.shadow.distance=4 \
    icon.shadow.color="${GLOW:-0x8000e5ff}"
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color="${SOFT:-$COMMENT}" \
    icon.shadow.drawing=off
fi
