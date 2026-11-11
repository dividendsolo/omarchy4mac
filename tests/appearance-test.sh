#!/bin/bash
# Checks Trigger > Appearance (Omarchy 4.5): bin/omarchy-appearance saves the
# window transparency and corners, Ghostty, SketchyBar and JankyBorders follow
# the saved choice, and the choice is read again after a restart (the bar and
# the borders read it when they start). Throwaway HOME; sketchybar, brew, hs
# and borders are stubs on PATH, so the running desktop is never touched.
#
#   tests/appearance-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
APPEARANCE="$HERE/../bin/omarchy-appearance"
fails=0
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
H="$T/home"; STUBS="$T/stubs"; LOG="$T/calls.log"
GMAC="$H/Library/Application Support/com.mitchellh.ghostty/config"
mkdir -p "$STUBS" "$(dirname "$GMAC")" "$H/.config/ghostty" "$T/sb"
printf 'theme = omarchy-jade\nbackground-opacity = 0.75\n' > "$GMAC"
printf 'theme = omarchy-jade\n' > "$H/.config/ghostty/config"
printf 'export BG="0xff112233"\nexport BG_TRANS="0xc0112233"\n' > "$T/sb/colors.sh"
# sketchybarrc also asks osascript and aerospace for the front app and workspace.
for cmd in sketchybar brew hs borders pgrep osascript aerospace; do
  printf '#!/bin/bash\necho "%s $*" >> "%s"\nexit 0\n' "$cmd" "$LOG" > "$STUBS/$cmd"
done
chmod +x "$STUBS"/*

ap() { env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" /bin/bash "$APPEARANCE" "$@" 2>&1; }
check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}
# bar_color: the color= the bar gets when sketchybarrc starts (a restart)
bar_color() {
  : > "$LOG"
  env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" CONFIG_DIR="$T/sb" /bin/bash "$HERE/../sketchybar/sketchybarrc" >/dev/null 2>&1
  grep -m1 -- '--bar' "$LOG" | grep -oE 'color=0x[0-9a-f]+' | head -1
}
# border_style: the style= JankyBorders gets when bordersrc starts (a restart)
border_style() {
  : > "$LOG"
  env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" /bin/bash "$HERE/../borders/bordersrc" >/dev/null 2>&1
  grep -m1 '^borders ' "$LOG" | grep -oE 'style=[a-z]+'
}
has() { grep -qx "$1" "$2"; }

echo "defaults (nothing chosen yet):"
check "transparency prints transparent" test "$(ap transparency)" = transparent
check "corners prints theme" test "$(ap corners)" = theme
check "bar keeps today's see-through color" test "$(bar_color)" = color=0xc0112233
check "borders keep today's round style" test "$(border_style)" = style=round

echo "transparency:"
ap transparency opaque >/dev/null
check "opaque is saved" test "$(ap transparency)" = opaque
check "opaque: Ghostty is solid (app-support config)" has 'background-opacity = 1' "$GMAC"
check "opaque: Ghostty is solid (XDG config)" has 'background-opacity = 1' "$H/.config/ghostty/config"
check "opaque: no duplicate opacity line" test "$(grep -c background-opacity "$GMAC")" = 1
check "opaque: the theme line is kept" has 'theme = omarchy-jade' "$GMAC"
check "opaque: the bar reloads" grep -q 'sketchybar --reload' "$LOG"
check "opaque: bar is solid after a restart" test "$(bar_color)" = color=0xff112233
ap transparency glassy >/dev/null
check "glassy: Ghostty is see-through" has 'background-opacity = 0.65' "$GMAC"
check "glassy: Ghostty blurs" has 'background-blur = 20' "$GMAC"
check "glassy: bar is glassy after a restart" test "$(bar_color)" = color=0x59112233
ap transparency transparent >/dev/null
check "transparent: Ghostty back to 0.75" has 'background-opacity = 0.75' "$GMAC"
check "transparent: no blur" has 'background-blur = false' "$GMAC"
check "transparent: bar back to 0xc0" test "$(bar_color)" = color=0xc0112233

echo "corners:"
ap corners sharp >/dev/null
check "sharp is saved" test "$(ap corners)" = sharp
check "sharp: borders restart" grep -q 'brew services restart borders' "$LOG"
check "sharp: square borders after a restart" test "$(border_style)" = style=square
ap corners rounded >/dev/null
check "rounded: round borders after a restart" test "$(border_style)" = style=round
ap corners theme >/dev/null
check "theme: back to the default" test "$(ap corners)" = theme

echo "bad input:"
before="$(cat "$GMAC")"
check "an unknown transparency fails" bash -c "! env -i HOME='$H' PATH='$STUBS:/usr/bin:/bin' /bin/bash '$APPEARANCE' transparency foggy >/dev/null 2>&1"
check "an unknown corner style fails" bash -c "! env -i HOME='$H' PATH='$STUBS:/usr/bin:/bin' /bin/bash '$APPEARANCE' corners wavy >/dev/null 2>&1"
check "an unknown choice changes nothing" test "$(cat "$GMAC")" = "$before"
check "the saved corners stay" test "$(ap corners)" = theme

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
