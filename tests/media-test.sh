#!/bin/bash
# Checks the bar's music item (sketchybar/plugins/media.sh): it shows whatever
# plays (Spotify, YouTube Music in Brave, any player) from macOS Now Playing,
# the way Omarchy 4's media widget does: a pause icon while playing, a play
# icon while paused, "Title  ·  Artist". media-control and sketchybar are
# stubs that log, so the running bar does not change.
#
#   tests/media-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="${MEDIA_PLUGIN:-$HERE/../sketchybar/plugins/media.sh}"
RC="${SKETCHYBARRC:-$HERE/../sketchybar/sketchybarrc}"
fails=0

check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

# run <now-playing JSON, or MISSING for no media-control>: runs the plugin.
run() {
  T="$(mktemp -d)"; LOG="$T/calls.log"; : > "$LOG"; mkdir -p "$T/stubs" "$T/config"
  printf 'export FG=0xfffg\nexport COMMENT=0xffdim\n' > "$T/config/colors.sh"
  printf '#!/bin/bash\nprintf "%%s\\n" "sketchybar $*" >> "%s"\n' "$LOG" > "$T/stubs/sketchybar"
  if [[ "$1" != MISSING ]]; then
    printf '%s\n' "$1" > "$T/now.json"
    printf '#!/bin/bash\n[[ "$1" == get ]] && cat "%s"\n' "$T/now.json" > "$T/stubs/media-control"
  fi
  chmod +x "$T/stubs"/*
  env -i HOME="$T" PATH="$T/stubs:/usr/bin:/bin" CONFIG_DIR="$T/config" NAME=media \
      MEDIA_CONTROL="$T/stubs/media-control" /bin/bash "$PLUGIN" >/dev/null 2>&1
}
logged() { grep -qF -- "$1" "$LOG"; }

YTM='{"bundleIdentifier":"com.brave.Browser.app.cinhimbnkkaeohfgghhklpknlkffjgod","title":"Training Montage (Rocky IV Score Mix)","artist":"Vince DiCola","playing":true}'

echo "YouTube Music (Brave web app) playing:"
run "$YTM"
check "shows Title  ·  Artist" logged 'label=Training Montage (Rocky IV Score Mix)  ·  Vince DiCola'
check "pause icon while playing" logged 'icon=󰏤'
check "bright while playing" logged 'label.color=0xfffg'
check "shows the next button" logged '--set media_next drawing=on'
rm -rf "$T"

echo "Spotify paused:"
run '{"bundleIdentifier":"com.spotify.client","title":"Hearts on Fire","artist":"Vince DiCola","playing":false}'
check "shows Title  ·  Artist" logged 'label=Hearts on Fire  ·  Vince DiCola'
check "play icon while paused" logged 'icon=󰐊'
check "dimmed while paused" logged 'label.color=0xffdim'
rm -rf "$T"

echo "no artist:"
run '{"title":"Untitled stream","playing":true}'
check "shows the title alone" logged 'label=Untitled stream icon'
rm -rf "$T"

echo "nothing playing:"
run 'null'
check "hides the item and the next button" logged '--set media drawing=off --set media_next drawing=off'
rm -rf "$T"

echo "media-control not installed:"
run MISSING
check "hides the item and the next button" logged '--set media drawing=off --set media_next drawing=off'
rm -rf "$T"

echo "sketchybarrc:"
check "media item runs media.sh" grep -q 'script="$PLUGIN_DIR/media.sh"' "$RC"
check "click on the title toggles play/pause" grep -q 'toggle-play-pause' "$RC"
check "next button skips the track" grep -q 'next-track' "$RC"
check "next button has Omarchy's next icon (󰒭)" bash -c 'grep -A3 -F "add item media_next" "$1" | grep -qF "icon=\"󰒭\""' _ "$RC"
check "no Spotify-only AppleScript left" bash -c "! grep -q 'tell application \\\\\"Spotify\\\\\"' '$RC'"
check "title is 23 characters (Omarchy's 180 px)" grep -q 'label.max_chars=23' "$RC"

if pgrep -xq sketchybar && command -v media-control >/dev/null; then
  echo "running bar:"
  title="$(media-control get 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d or {}).get("title") or "")' 2>/dev/null)"
  sketchybar --trigger media_refresh; sleep 1
  shown="$(sketchybar --query media 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["geometry"]["drawing"], d["label"]["value"], sep="|")' 2>/dev/null || echo "no media item|")"
  if [[ -n "$title" ]]; then
    check "shows what plays now ($title)" bash -c '[[ "$1" == "on|$2"* ]]' _ "$shown" "$title"
    next_icon="$(sketchybar --query media_next 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["icon"]["value"])' 2>/dev/null)"
    check "next button is drawn with its icon" test "$next_icon" = "󰒭"
  else
    check "hidden when nothing plays" bash -c '[[ "$1" == off\|* ]]' _ "$shown"
  fi
else
  echo "running bar: skipped (SketchyBar or media-control missing)"
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
