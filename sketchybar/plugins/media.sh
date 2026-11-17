#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

hide() { sketchybar --set media drawing=off --set media_next drawing=off; exit 0; }

MC="${MEDIA_CONTROL:-$(command -v media-control || echo /opt/homebrew/bin/media-control)}"
[ -x "$MC" ] || hide

NOW="$("$MC" get 2>/dev/null | python3 -c '
import json, sys
try: d = json.load(sys.stdin)
except Exception: d = None
if d and d.get("title"):
    print("%d\t%s\t%s" % (bool(d.get("playing")), d["title"], d.get("artist") or ""))
' 2>/dev/null)"
[ -n "$NOW" ] || hide
IFS=$'\t' read -r PLAYING TITLE ARTIST <<< "$NOW"

TEXT="$TITLE"
[ -n "$ARTIST" ] && TEXT="$TITLE  ·  $ARTIST"

if [ "$PLAYING" = 1 ]; then
  ICON="󰏤"; COLOR="$FG"
else
  ICON="󰐊"; COLOR="$COMMENT"
fi

sketchybar --set media drawing=on label="$TEXT" icon="$ICON" \
                       icon.color="$COLOR" label.color="$COLOR" \
           --set media_next drawing=on icon.color="$COLOR"
