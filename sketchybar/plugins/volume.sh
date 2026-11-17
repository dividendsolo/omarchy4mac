#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
fi

[ -z "$VOLUME" ] && exit 0

DEVICE="$(SwitchAudioSource -c 2>/dev/null)"

case "$DEVICE" in
  ""|*[Ss]peaker*|*MacBook*|*[Bb]uilt-in*|*Display*|*Monitor*|*TV*|*HDMI*|*HomePod*)
    case "$VOLUME" in
      100|[6-9][0-9])   ICON="󰕾" ;;
      [3-5][0-9])       ICON="󰖀" ;;
      [1-9]|[1-2][0-9]) ICON="󰕿" ;;
      *)                ICON="󰝟" ;;
    esac
    ;;
  *)
    ICON=""
    ;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$CYAN" \
  label="${VOLUME}%"
