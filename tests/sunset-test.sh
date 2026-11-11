#!/bin/bash
# Checks the Friday sunset item (sketchybar/plugins/sunset.sh): on Friday the bar
# shows the sunset time, as a reminder to stop working.
# sketchybar and curl are stubs on PATH, so the running bar is never touched.
#
#   tests/sunset-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$HERE/../sketchybar/plugins/sunset.sh"
fails=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config/plugins"
# colors.sh is written by bin/theme and is not in git, so the test brings its own.
printf 'export RED="0xffff5f4a"\nexport ORANGE="0xffff6a3d"\n' > "$TMP/config/colors.sh"
cp "$HERE/../sketchybar/plugins/displays.sh" "$TMP/config/plugins/"
CONFIG_DIR="$TMP/config"
cat > "$TMP/bin/sketchybar" <<'STUB'
#!/bin/bash
[[ "$1" == "--query" ]] && { echo '[{"arrangement-id": 1, "DirectDisplayID": 0}]'; exit 0; }
echo "$*" >> "$SUNSET_TEST_LOG"
STUB
cat > "$TMP/bin/curl" <<'STUB'
#!/bin/bash
echo "$*" >> "${CURL_TEST_LOG:-/dev/null}"
echo "${SUNSET_TEST_WTTR}"
STUB
chmod +x "$TMP/bin/"*

check() { # check <description> <expected substring> <actual>
  if [[ "$3" == *"$2"* ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2' in '$3')"; fails=$((fails + 1)); fi
}

run() { # run <name> <YYYY-MM-DD HH:MM> <wttr sunset HH:MM:SS>: prints what the plugin set
  : > "$TMP/log"; rm -f "$TMP/cache"
  PATH="$TMP/bin:$PATH" CONFIG_DIR="$CONFIG_DIR" NAME="$1" SUNSET_NOW="$2" \
    SUNSET_CACHE="$TMP/cache" SUNSET_TEST_WTTR="$3" SUNSET_TEST_LOG="$TMP/log" bash "$PLUGIN"
  cat "$TMP/log"
}

echo "sunset.sh:"
out="$(run sunset_center "2026-11-06 14:00" "17:17:17")"
check "Friday afternoon: shows the sunset time" "label=5:17 PM" "$out"
check "Friday afternoon: the sunset-down icon (md-weather_sunset_down)" "icon="$'\U000f059b' "$out"
check "Friday afternoon: drawn on the external display" "drawing=on associated_display=1" "$out"
out="$(run sunset_center "2026-11-06 16:50" "17:17:17")"
check "Friday, under 30 minutes to go: red" "label.color=0xffff5f4a" "$out"
out="$(run sunset_center "2026-11-06 18:00" "17:17:17")"
check "Friday after sunset: still shown, red" "label.color=0xffff5f4a" "$out"
out="$(run sunset_center "2026-11-05 14:00" "17:17:17")"
check "Thursday: hidden" "drawing=off" "$out"
out="$(run sunset_center "2026-11-07 14:00" "17:17:17")"
check "Saturday: hidden" "drawing=off" "$out"
out="$(run sunset_center "2026-11-06 14:00" "")"
check "Friday, wttr.in down: hidden" "drawing=off" "$out"

echo "wttr.in over https (#45):"
for cmd in "$PLUGIN" "$HERE/../sketchybar/plugins/weather.sh" "$HERE/../bin/omarchy-notice weather"; do
  : > "$TMP/curl.log"; rm -f "$TMP/cache"
  PATH="$TMP/bin:$PATH" CONFIG_DIR="$CONFIG_DIR" NAME=sunset_center SUNSET_NOW="2026-11-06 14:00" SUNSET_CACHE="$TMP/cache" \
    SUNSET_TEST_LOG="$TMP/log" CURL_TEST_LOG="$TMP/curl.log" bash $cmd >/dev/null 2>&1
  url="$(grep -o '[^ ]*wttr.in[^ ]*' "$TMP/curl.log")"
  check "${cmd##*/} fetches https://wttr.in" "https://wttr.in/" "$url"
done

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
