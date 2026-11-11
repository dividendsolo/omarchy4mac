#!/bin/bash
# Checks bin/omarchy-workspace-layout (Super+L, Omarchy 4.5) against a fake
# `aerospace` that logs every call: the focused workspace cycles tiles ->
# accordion -> floating -> tiles, floating floats only the windows that were
# tiled (and tiles back only those), and `restore` re-applies the saved layout
# after an AeroSpace restart.
#
#   tests/workspace-layout-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin/omarchy-workspace-layout"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

# The fake AeroSpace: workspace 2 is focused, its root layout is $TMP/root,
# and its windows ("<id> <layout>" lines) are $TMP/windows.
cat >"$TMP/aerospace" <<'SH'
#!/bin/bash
echo "$*" >>"$FAKE/log"
case "$*" in
  "list-workspaces --focused") echo 2 ;;
  "list-workspaces --focused --format %{workspace-root-container-layout}") cat "$FAKE/root" ;;
  "list-windows --workspace 2 --format %{window-id} %{window-layout}") cat "$FAKE/windows" ;;
esac
SH
chmod +x "$TMP/aerospace"
export FAKE="$TMP" AEROSPACE="$TMP/aerospace" XDG_STATE_HOME="$TMP/state"
STATE="$TMP/state/omarchy/workspace-layouts"

run() { : >"$TMP/log"; "$BIN" "$@"; }
calls() { grep -v '^list-' "$TMP/log" | tr '\n' ';'; }

echo "omarchy-workspace-layout:"
echo h_tiles >"$TMP/root"
printf '11 h_tiles\n12 h_tiles\n13 floating\n' >"$TMP/windows"

run
check "tiles -> accordion" "layout --workspace 2 --root accordion;" "$(calls)"
check "accordion is saved" accordion "$(cat "$STATE/2")"

echo h_accordion >"$TMP/root"
run
check "accordion -> floating floats the tiled windows only" \
  "layout --window-id 11 floating;layout --window-id 12 floating;" "$(calls)"
check "floating is saved" floating "$(cat "$STATE/2")"

printf '11 floating\n12 floating\n13 floating\n' >"$TMP/windows"
run
check "floating -> tiles tiles back only the windows it floated" \
  "layout --window-id 11 tiling;layout --window-id 12 tiling;layout --workspace 2 --root tiles;" "$(calls)"
check "tiles is saved" tiles "$(cat "$STATE/2")"

# After a restart AeroSpace rebuilds every workspace in tiles; restore puts
# back what was saved.
echo floating >"$STATE/2"
printf '21 h_tiles\n' >"$TMP/windows"
run restore
check "restore re-applies floating" "layout --window-id 21 floating;" "$(calls)"

echo accordion >"$STATE/2"
run restore
check "restore re-applies accordion" "layout --workspace 2 --root accordion;" "$(calls)"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
