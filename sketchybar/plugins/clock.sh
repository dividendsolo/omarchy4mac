#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

# Right-click turns the seconds on or off (Omarchy 4.5's clock format with live
# seconds, omacom/omarchy#7586); left-click opens Date & Time, as before.
SECONDS_FILE="$HOME/.config/omarchy/clock-seconds"
if [ "$SENDER" = mouse.clicked ]; then
  [ "$BUTTON" = right ] || exec open "x-apple.systempreferences:com.apple.Date-Time-Settings.extension"
  if [ -e "$SECONDS_FILE" ]; then rm -f "$SECONDS_FILE"; else mkdir -p "${SECONDS_FILE%/*}" && touch "$SECONDS_FILE"; fi
fi

# The bar's own timer (update_freq) runs the clock, never a wait until a wall-clock
# time, so the repeated hour at the end of daylight saving changes nothing
# (omacom/omarchy#16684). CLOCK_NOW (epoch seconds) lets the tests pick the time.
NOW="${CLOCK_NOW:-$(date +%s)}"
if [ -e "$SECONDS_FILE" ]; then
  LABEL="$(date -r "$NOW" '+%a  %-I:%M:%S %p')"; FREQ=1
  # Each second only the time changes; the layout below runs once a minute.
  if [ "$SENDER" = routine ] && [ "$(date -r "$NOW" +%S)" != 00 ]; then
    sketchybar --set clock label="$LABEL" --set clock_right label="$LABEL"
    exit 0
  fi
else
  LABEL="$(date -r "$NOW" '+%a  %-I:%M %p')"; FREQ=10
fi
ICON="󰥔"
THEME="$(cat "$HOME/.config/theme-switcher/current" 2>/dev/null || echo "?")"

source "$CONFIG_DIR/plugins/displays.sh"

# A failed display lookup (it happens under heavy load) must not hide the clock:
# keep where it is drawn and only refresh the time.
if [ "$DISPLAYS_OK" = 0 ]; then
  sketchybar --set clock label="$LABEL" update_freq="$FREQ" --set clock_right label="$LABEL"
  exit 0
fi

if [ "$BUILTIN" != "-" ]; then
  sketchybar --set clock_right drawing=on associated_display="$BUILTIN" \
                   icon="$ICON" icon.color="$MAGENTA" label="$LABEL" label.color="$FG"
else
  sketchybar --set clock_right drawing=off
fi

if [ "$OTHERS" != "-" ]; then
  sketchybar --set clock drawing=on associated_display="$OTHERS" update_freq="$FREQ" \
                   icon="$ICON" icon.color="$MAGENTA" label="$LABEL" label.color="$FG" \
             --set theme_name drawing=on associated_display="$OTHERS" \
                   label="$THEME" label.color="$FG"
else
  # Hidden, the clock item still ticks: its script draws the right-side clock.
  sketchybar --set clock drawing=off update_freq="$FREQ" --set theme_name drawing=off
fi
