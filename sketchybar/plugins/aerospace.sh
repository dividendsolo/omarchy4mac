#!/usr/bin/env bash
# Highlight the focused AeroSpace workspace.
# Workspace id is derived from $NAME (e.g. "space.3" → "3").
# $FOCUSED_WORKSPACE is set by the aerospace_workspace_change trigger.

# Homebrew last, so a test's stub aerospace comes first (#54).
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

# The wheel over a workspace item: up goes to the workspace before, down to the
# one after, and the ends stop there (Omarchy 4.5, omacom/omarchy#15256).
# SketchyBar sends at most one scroll per 150 ms, so a trackpad flick moves a few.
if [ "$SENDER" = mouse.scrolled ]; then
  if [ "${SCROLL_DELTA:-0}" -gt 0 ]; then aerospace workspace prev
  elif [ "${SCROLL_DELTA:-0}" -lt 0 ]; then aerospace workspace next
  fi 2>/dev/null # past the last workspace, aerospace complains; keep the log quiet
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
