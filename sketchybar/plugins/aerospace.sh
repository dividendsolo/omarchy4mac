#!/usr/bin/env bash

PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if [ "$SENDER" = mouse.scrolled ]; then
  if [ "${SCROLL_DELTA:-0}" -gt 0 ]; then aerospace workspace prev
  elif [ "${SCROLL_DELTA:-0}" -lt 0 ]; then aerospace workspace next
  fi 2>/dev/null
  exit 0
fi

source "$CONFIG_DIR/colors.sh"

SID="${NAME#space.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

if [ "$SID" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$BLUE" \
    icon.color="$BG"
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color="$FG"
fi
