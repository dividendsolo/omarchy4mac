#!/usr/bin/env bash
for _ in 1 2 3; do
read -r BUILTIN OTHERS <<<"$(
  sketchybar --query displays 2>/dev/null | python3 -c '
import ctypes, ctypes.util, json, sys

cg = ctypes.CDLL(ctypes.util.find_library("CoreGraphics"))
count = ctypes.c_uint32()
ids = (ctypes.c_uint32 * 16)()
cg.CGGetActiveDisplayList(16, ids, ctypes.byref(count))
builtin_ddids = {ids[i] for i in range(count.value) if cg.CGDisplayIsBuiltin(ids[i])}

builtin, others = [], []
for d in json.load(sys.stdin):
    arrangement = str(d["arrangement-id"])
    (builtin if d["DirectDisplayID"] in builtin_ddids else others).append(arrangement)

print(",".join(builtin) or "-", ",".join(others) or "-")
' 2>/dev/null
)"
[ -n "$BUILTIN" ] && break
sleep 0.3
done
DISPLAYS_OK=1
if [ -z "$BUILTIN" ]; then
  DISPLAYS_OK=0; BUILTIN="-"; OTHERS="0"
  echo "$(date '+%F %T') displays.sh: detection failed (${NAME:-?})" >> "$HOME/.cache/sketchybar-displays.log"
fi

center_item() {
  local item="$1"; shift
  if [ "$DISPLAYS_OK" = 0 ]; then
    sketchybar --set "$item" "$@"
  elif [ "$OTHERS" != "-" ]; then
    sketchybar --set "$item" drawing=on associated_display="$OTHERS" "$@"
  else
    sketchybar --set "$item" drawing=off
  fi
}
