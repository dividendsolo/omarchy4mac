#!/usr/bin/env bash
# Friday sunset: on Friday the bar shows today's sunset time, so work stops
# at sunset. Hidden on every other day. The label turns red in
# the last 30 minutes before sunset and stays red after it.
#
# Sunset comes from wttr.in for the current location (IP-based, like
# weather.sh), fetched once per day and cached. Hidden when it cannot be read.
#
# Two copies, like standup.sh: the centre copy (sunset_center) on the external
# displays, the right copy (sunset) on the notched built-in panel.
#
# Test hooks: SUNSET_NOW="YYYY-MM-DD HH:MM" fakes the clock, SUNSET_CACHE moves
# the cache file (tests/sunset-test.sh).
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

if [ -n "${SUNSET_NOW:-}" ]; then
  NOW_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "$SUNSET_NOW:00" +%s)"
else
  NOW_EPOCH="$(date +%s)"
fi
TODAY="$(date -j -r "$NOW_EPOCH" +%F)"
WEEKDAY="$(date -j -r "$NOW_EPOCH" +%u)" # 1 = Monday ... 5 = Friday

if [ "$NAME" = "sunset_center" ]; then
  TARGET="$OTHERS"
else
  TARGET="$BUILTIN"
fi

hide() { sketchybar --set "$NAME" drawing=off; exit 0; }

[ "$WEEKDAY" = 5 ] || hide
# A failed display lookup must not hide the item (like clock.sh): keep where it
# is drawn and only refresh the label.
if [ "$DISPLAYS_OK" = 1 ]; then
  [ -n "$TARGET" ] && [ "$TARGET" != "-" ] || hide
  PLACE=(associated_display="$TARGET")
else
  PLACE=()
fi

CACHE="${SUNSET_CACHE:-$HOME/.cache/sketchybar-sunset}"
SUNSET=""
if [ -f "$CACHE" ]; then
  read -r CACHED_DAY CACHED_SUNSET < "$CACHE"
  [ "$CACHED_DAY" = "$TODAY" ] && SUNSET="$CACHED_SUNSET"
fi
if [ -z "$SUNSET" ]; then
  SUNSET="$(curl -s --max-time 5 'https://wttr.in/?format=%s' 2>/dev/null | tr -d '[:space:]')"
  [[ "$SUNSET" =~ ^[0-9]{2}:[0-9]{2}(:[0-9]{2})?$ ]] || hide
  mkdir -p "$(dirname "$CACHE")"
  echo "$TODAY $SUNSET" > "$CACHE"
fi

SUNSET_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "$TODAY ${SUNSET:0:5}:00" +%s)"
LABEL="$(date -j -r "$SUNSET_EPOCH" '+%-I:%M %p')"

if [ $(( SUNSET_EPOCH - NOW_EPOCH )) -le 1800 ]; then
  COLOR="$RED"
else
  COLOR="$ORANGE"
fi

sketchybar --set "$NAME" drawing=on "${PLACE[@]}" \
  icon=$'\U000f059b' icon.color="$COLOR" \
  label="$LABEL" label.color="$COLOR"
