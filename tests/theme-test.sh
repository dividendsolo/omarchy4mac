#!/bin/bash
# End-to-end tests for bin/theme, run the way a hotkey runs it: no terminal,
# macOS system bash (3.2), in a throwaway HOME. Every tool that would touch
# the real desktop (osascript, hs, sketchybar, nvim, pkill, pgrep) is a stub
# that logs its arguments, so nothing on this Mac changes.
#
#   tests/theme-test.sh                 test bin/theme next to this file
#   THEME_BIN=/path/to/theme tests/theme-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
THEME_BIN="${THEME_BIN:-$HERE/../bin/theme}"
FIXTURE="$HERE/fixtures/theme-cache/jade"
fails=0

setup() {
  T="$(mktemp -d)"
  H="$T/home"; STUBS="$T/stubs"; LOG="$T/calls.log"
  mkdir -p "$H/.config/theme-switcher/cache" "$H/Pictures/Wallpapers" \
           "$H/.config/ghostty/themes" "$H/.claude" "$H/.config/sketchybar" "$STUBS"
  # Two themes with the same colors: "withwall" has a wallpaper, "nowall" has none.
  cp -R "$FIXTURE" "$H/.config/theme-switcher/cache/withwall"
  cp -R "$FIXTURE" "$H/.config/theme-switcher/cache/nowall"
  : > "$H/Pictures/Wallpapers/withwall_1.jpg"
  printf 'theme = omarchy-withwall\n' > "$H/.config/ghostty/config"
  : > "$LOG"
  for cmd in osascript hs sketchybar nvim pkill; do
    printf '#!/bin/bash\necho "%s $*" >> "%s"\nexit 0\n' "$cmd" "$LOG" > "$STUBS/$cmd"
  done
  # pgrep: Hammerspoon is running, nothing else is.
  printf '#!/bin/bash\necho "pgrep $*" >> "%s"\n[[ "$*" == *Hammerspoon* ]]\n' "$LOG" > "$STUBS/pgrep"
  chmod +x "$STUBS"/*
}

# run <theme name>: no tty on stdout, stub PATH first, /bin/bash via env.
run() {
  OUT="$T/out.txt"
  env -i HOME="$H" USER="$USER" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
      XDG_CONFIG_HOME="$H/.config" CLAUDE_CONFIG_DIR="$H/.claude" \
      /bin/bash "$THEME_BIN" "$1" > "$OUT" 2>&1 < /dev/null
  CODE=$?
  sleep 0.3   # the alert is sent in the background
  LC_ALL=C sed $'s/\033\\[[0-9;]*m//g' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
}

check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

echo "theme with no wallpaper (bash 3.2, hotkey):"
setup; run nowall
check "exits 0" test "$CODE" -eq 0
check "runs to the end (prints done.)" grep -q '^done\.' "$OUT"
check "writes the state file" grep -qx nowall "$H/.config/theme-switcher/current"
check "points Ghostty at the theme" grep -qx 'theme = omarchy-nowall' "$H/.config/ghostty/config"
check "does not set a desktop picture" bash -c "! grep -q 'set picture' '$LOG'"
check "shows one alert with the wallpaper message" \
  grep -qF 'hs -c hs.alert.show([[Switched to nowall. No wallpaper for this theme in ~/Pictures/Wallpapers, so the previous wallpaper stays.]], 5)' "$LOG"
rm -rf "$T"

echo "theme with a wallpaper (bash 3.2, hotkey):"
setup; run withwall
check "exits 0" test "$CODE" -eq 0
check "runs to the end (prints done.)" grep -q '^done\.' "$OUT"
check "writes the state file" grep -qx withwall "$H/.config/theme-switcher/current"
check "sets the wallpaper" grep -q 'set picture of every desktop to ".*withwall_1.jpg"' "$LOG"
check "shows no alert" bash -c "! grep -q 'hs.alert' '$LOG'"
check "sends no macOS notification" bash -c "! grep -q 'display notification' '$LOG'"
rm -rf "$T"

echo "terminal output:"
setup; run withwall
check "Ghostty line says open windows reload through Hammerspoon" \
  grep -q 'ghostty  open windows reload through Hammerspoon' "$OUT"
check "no 'new windows only' line" bash -c "! grep -q 'new windows only' '$OUT'"
rm -rf "$T"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
