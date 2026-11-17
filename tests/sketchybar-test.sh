#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RC="${SKETCHYBARRC:-$HERE/../sketchybar/sketchybarrc}"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}
in_range() {
  if (( $4 >= $2 && $4 <= $3 )); then echo "  ok    $1 ($4 px)"
  else echo "  FAIL  $1 (expected $2-$3 px, got $4 px)"; fails=$((fails + 1)); fi
}

echo "sketchybarrc:"
max="$(awk '/--add item media left/{f=1} f&&/label.max_chars=/{sub(/.*label.max_chars=/,""); print $1; exit}' "$RC")"
check "music title is at most 23 characters" 23 "$max"
topmost="$(grep -o 'topmost=[a-z]*' "$RC" | head -1)"
check "the bar is drawn above the menu bar" "topmost=on" "$topmost"

if pgrep -xq sketchybar; then
  echo "running bar:"
  font="$(sketchybar --query media | python3 -c 'import json,sys; print(json.load(sys.stdin)["label"]["font"])')"
  sketchybar --add item width_test left --set width_test icon.drawing=off \
             label.font="$font" label.max_chars="$max" scroll_texts=on
  width() {
    sketchybar --set width_test label="$1"; sleep 0.3
    sketchybar --query width_test | python3 -c \
      'import json,sys; r=json.load(sys.stdin)["bounding_rects"]; print(int(next(iter(r.values()))["size"][0]))'
  }
  w1="$(width A)"; w2="$(width AA)"; w40="$(width "$(printf 'A%.0s' $(seq 1 40))")"
  sketchybar --remove width_test
  in_range "long title shows about 180 px, like Omarchy" 175 185 $(( w40 - w1 + (w2 - w1) ))
else
  echo "running bar: skipped (SketchyBar not running)"
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
