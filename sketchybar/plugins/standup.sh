#!/usr/bin/env bash
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

ELAPSED="$(ps -p "$PID" -o etime= 2>/dev/null | awk -F'[-:]' '
  { gsub(/ /,"") }
  NF==4 { print $1*86400+$2*3600+$3*60+$4; next }
  NF==3 { print $1*3600+$2*60+$3; next }
  NF==2 { print $1*60+$2 }')"
[ -n "$ELAPSED" ] || { sketchybar --set "$NAME" drawing=off; exit 0; }

if [ $(( (ELAPSED / PERIOD) % 2 )) -eq 0 ]; then
  ICON=$'\U000f0f48'
  COLOR="$BLUE"
else
  ICON=$'\U000f064d'
  COLOR="$GREEN"
fi

sketchybar --set "$NAME" drawing=on associated_display="$TARGET" \
  icon="$ICON" icon.color="$COLOR" icon.font="Hack Nerd Font:Bold:14.0" \
  label.drawing=off label="" background.drawing=off
