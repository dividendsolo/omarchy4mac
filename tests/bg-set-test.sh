#!/bin/bash
# Tests for bin/omarchy-bg-set and bin/omarchy-toggle-intros (Omarchy 4.5 video backgrounds and theme
# intros) in a throwaway HOME. osascript, qlmanage and defaults are stubs, and
# the player (omarchy-video-wallpaper) is a stub that logs its arguments and
# waits, so nothing on this Mac changes.
#
#   tests/bg-set-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin/omarchy-bg-set"
fails=0
check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

setup() {
  T="$(mktemp -d)"; H="$T/home"; STUBS="$T/stubs"; W="$H/Pictures/Wallpapers"
  mkdir -p "$W/intros" "$H/.local/bin" "$STUBS"
  cat > "$STUBS/osascript" <<EOF
#!/bin/bash
[[ "\$*" == *"get picture"* ]] && { cat "$T/current" 2>/dev/null; exit 0; }
echo "\${@: -1}" >> "$T/picture.log"
# macOS keeps one picture per screen arrangement (Index.plist): a set reaches only the connected one
mkdir -p "$T/shown"; echo "\${@: -1}" > "$T/shown/\$(cat "$T/arrangement" 2>/dev/null || echo laptop)"
EOF
  # qlmanage -t -s <n> -o <dir> <file> writes <dir>/<file name>.png
  cat > "$STUBS/qlmanage" <<EOF
#!/bin/bash
echo still > "\$5/\${6##*/}.png"
EOF
  printf '#!/bin/bash\ncat "%s/reduce" 2>/dev/null\n' "$T" > "$STUBS/defaults"
  cat > "$H/.local/bin/omarchy-video-wallpaper" <<EOF
#!/bin/bash
echo "\$*" >> "$T/player.log"
[[ "\$1" == --once ]] || while :; do sleep 0.1; done   # stays the player process, as the real one does
EOF
  chmod +x "$STUBS"/* "$H/.local/bin/omarchy-video-wallpaper"
}
run() { env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" /bin/bash "$BIN" "$@"; sleep 0.3; }
player_alive() { kill -0 "$(cat "$H/.local/state/omarchy/background-video.pid" 2>/dev/null)" 2>/dev/null; }
teardown() { pkill -f "$T/" 2>/dev/null; rm -rf "$T"; }

echo "a video background:"
setup
: > "$W/clip.mp4"
run "$W/clip.mp4"
check "the lock screen gets a still frame as the desktop picture" grep -qxF "$H/.cache/omarchy/background-stills/clip.mp4.png" "$T/picture.log"
check "the player loops the video" grep -qxF "$W/clip.mp4" "$T/player.log"
check "the player keeps running" player_alive
pid="$(cat "$H/.local/state/omarchy/background-video.pid")"

echo "an image after a video:"
: > "$W/still.jpg"
run "$W/still.jpg"
check "the video player stops" bash -c "! kill -0 $pid 2>/dev/null"
check "the image is the desktop picture" grep -qxF "$W/still.jpg" "$T/picture.log"
check "no video is remembered" test ! -e "$H/.local/state/omarchy/background-video"
teardown

echo "theme intros:"
setup
: > "$W/jade_1.webp"; : > "$W/intros/jade_1.mp4"
run "$W/jade_1.webp"
check "an image with an intro plays it once" grep -qxF -- "--once $W/intros/jade_1.mp4" "$T/player.log"
rm -f "$T/player.log"
toggle() { env -i HOME="$H" PATH="/usr/bin:/bin" /bin/bash "$HERE/../bin/omarchy-toggle-intros"; }
check "Animations > Theme Intros turns intros off" test "$(toggle)" = "Theme intros|||Disabled"
run "$W/jade_1.webp"
check "intros off: no intro" test ! -e "$T/player.log"
check "Animations > Theme Intros turns them back on" test "$(toggle)" = "Theme intros|||Enabled"
echo 1 > "$T/reduce"
run "$W/jade_1.webp"
check "Reduce motion on: no intro" test ! -e "$T/player.log"
rm -f "$T/reduce"

echo "login:"
echo "$W/jade_1.webp" > "$T/current"
run --login 111
check "a new login plays the current background's intro" grep -qxF -- "--once $W/intros/jade_1.mp4" "$T/player.log"
rm -f "$T/player.log"
run --login 111
check "a config reload does not play it again" test ! -e "$T/player.log"
: > "$W/clip.mp4"; run "$W/clip.mp4"; pkill -f "$H/.local/bin/omarchy-video-wallpaper $W/clip.mp4"; sleep 0.2; rm -f "$T/player.log"
run --login 222
check "a login restarts the video background" grep -qxF "$W/clip.mp4" "$T/player.log"
check "the restarted player keeps running" player_alive
teardown

echo "a screen change (#69):"
setup
screens() { echo "$1" > "$T/arrangement"; }
shown() { cat "$T/shown/$1" 2>/dev/null; }
: > "$W/jade-horse.webp"; : > "$W/big-eye.webp"
screens laptop; run "$W/jade-horse.webp"
screens docked; run "$W/big-eye.webp"
check "the theme switch reaches only the connected screens" test "$(shown laptop)" = "$W/jade-horse.webp"
screens laptop; run --reapply
check "unplugged: the laptop shows the current wallpaper" test "$(shown laptop)" = "$W/big-eye.webp"
: > "$W/clip.mp4"
screens docked; run "$W/clip.mp4"
screens laptop; rm -f "$T/player.log"; run --reapply
check "unplugged: the laptop shows the video's still frame" test "$(shown laptop)" = "$H/.cache/omarchy/background-stills/clip.mp4.png"
check "the video player is not started twice" test ! -e "$T/player.log"
screens docked; run "$W/big-eye.webp"; screens laptop; run --reapply
check "after a video, an image is reapplied, not the old still" test "$(shown laptop)" = "$W/big-eye.webp"
check "Hammerspoon reapplies the background when the screens change" \
  bash -c "grep -q 'hs.screen.watcher.new' '$HERE/../hammerspoon/init.lua' && grep -q 'omarchy-bg-set --reapply' '$HERE/../hammerspoon/init.lua'"
teardown

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
