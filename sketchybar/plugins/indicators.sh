#!/usr/bin/env bash
# State indicators, Omarchy-bar style: shown only while the state is on.
# Stay awake (caffeinate) and Do Not Disturb (an active Focus assertion).
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

if pgrep -x caffeinate >/dev/null 2>&1; then
  center_item indicator_awake icon="󰅶" icon.color="$YELLOW"
else
  sketchybar --set indicator_awake drawing=off
fi

DND_DB="$HOME/Library/DoNotDisturb/DB/Assertions.json"
if [ -f "$DND_DB" ] && plutil -convert json -o - "$DND_DB" 2>/dev/null \
     | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if any(r.get("storeAssertionRecords") for r in d.get("data",[])) else 1)' 2>/dev/null; then
  center_item indicator_dnd icon="󰂛" icon.color="$MAGENTA"
else
  sketchybar --set indicator_dnd drawing=off
fi
