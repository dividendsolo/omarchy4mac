#!/usr/bin/env bash
# Shared by the centre-cluster plugins (clock, weather, updates, indicators).
# Exports BUILTIN and OTHERS: sketchybar arrangement ids for the notched
# built-in panel and for the external displays ("-" when absent).
#
# The built-in display has a notch, so centered items are lost behind it. Rather
# than switching the whole bar to one layout or the other, pin each variant to
# the displays it suits: centered on the externals, right-side (in front of the
# battery) on the built-in. Both can be drawn at once, on different screens.
#
# sketchybar's associated_display takes arrangement ids, so map the built-in's
# DirectDisplayID (per CoreGraphics, the authority on which panel is built-in)
# through `sketchybar --query displays` to get its arrangement id.
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
# If anything above failed, fall back to the plain centered layout everywhere.
[ -n "$BUILTIN" ] || { BUILTIN="-"; OTHERS="0"; }

# Show a centre item on the externals only; the notch eats the centre on the
# built-in. Usage: center_item <name> [--set args...]
center_item() {
  local item="$1"; shift
  if [ "$OTHERS" != "-" ]; then
    sketchybar --set "$item" drawing=on associated_display="$OTHERS" "$@"
  else
    sketchybar --set "$item" drawing=off
  fi
}
