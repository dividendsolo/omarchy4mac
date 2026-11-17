#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

if [ -n "${SUNSET_NOW:-}" ]; then
  NOW_EPOCH="$(date -j -f '%Y-%m-%d %H:%M:%S' "$SUNSET_NOW:00" +%s)"
else
  NOW_EPOCH="$(date +%s)"
fi
TODAY="$(date -j -r "$NOW_EPOCH" +%F)"
WEEKDAY="$(date -j -r "$NOW_EPOCH" +%u)"

if [ "$NAME" = "sunset_center" ]; then
  TARGET="$OTHERS"
else
  TARGET="$BUILTIN"
fi

hide() { sketchybar --set "$NAME" drawing=off; exit 0; }

[ "$WEEKDAY" = 5 ] || hide
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
