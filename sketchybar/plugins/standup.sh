#!/usr/bin/env bash
# Stand-up / sit-down state for the interval timer (~/.hermes/standup_timer.sh).
# The timer alternates 30 minutes seated, then 30 minutes standing. The state is
# derived from the age of the running timer process, so the timer needs no state
# file and does NOT have to be restarted when this widget changes.
#
# Two copies of the widget, one per display layout, following the same idiom as
# clock.sh: the centre copy sits next to the centred theme name on the external
# displays, the right copy sits next to theme_name_right on the built-in panel.
#   NAME=standup         -> right cluster, built-in panel
#   NAME=standup_center  -> centre cluster, external displays
#
# Phase 0 (first 30 min, and every other block after) = sitting.
# Phase 1 = standing.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

PIDFILE="$HOME/.hermes/.standup_timer.pid"
PERIOD=1800

if [ "$NAME" = "standup_center" ]; then
  TARGET="$OTHERS"
else
  TARGET="$BUILTIN"
fi

PID="$(cat "$PIDFILE" 2>/dev/null)"
if [ -z "$TARGET" ] || [ "$TARGET" = "-" ] || [ -z "$PID" ] || ! kill -0 "$PID" 2>/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# ps etime is [[dd-]hh:]mm:ss; convert to seconds.
ELAPSED="$(ps -p "$PID" -o etime= 2>/dev/null | awk -F'[-:]' '
  { gsub(/ /,"") }
  NF==4 { print $1*86400+$2*3600+$3*60+$4; next }
  NF==3 { print $1*3600+$2*60+$3; next }
  NF==2 { print $1*60+$2 }')"
[ -n "$ELAPSED" ] || { sketchybar --set "$NAME" drawing=off; exit 0; }

if [ $(( (ELAPSED / PERIOD) % 2 )) -eq 0 ]; then
  ICON=$'\U000f0f48'   # md-chair_rolling — seated
  COLOR="$BLUE"
else
  ICON=$'\U000f064d'   # md-human_male — standing
  COLOR="$GREEN"
fi

# Restate the full style on every run so a leftover debug style cannot stick.
sketchybar --set "$NAME" drawing=on associated_display="$TARGET" \
  icon="$ICON" icon.color="$COLOR" icon.font="Hack Nerd Font:Bold:14.0" \
  label.drawing=off label="" background.drawing=off
