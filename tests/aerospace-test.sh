#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

get_file() {
  python3 - "$TOML" "$1" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
for k in sys.argv[2].split("."):
    d = d.get(k, "") if isinstance(d, dict) else ""
print(d)
PY
}

echo "aerospace.toml:"
check "workspaces start in tiles" tiles "$(get_file default-root-container-layout)"
check "outer.top leaves room for the bar" 40 "$(get_file gaps.outer.top)"
for key in alt-f cmd-alt-f cmd-ctrl-f; do
  check "$key is fullscreen below the bar" fullscreen "$(get_file mode.main.binding.$key)"
done
check "alt-a still toggles accordion" "layout accordion tiles" "$(get_file mode.main.binding.alt-a)"
check "alt-l cycles the workspace layout" \
  'exec-and-forget $HOME/.local/bin/omarchy-workspace-layout cycle' "$(get_file mode.main.binding.alt-l)"
check "alt-m minimizes to the Dock" macos-native-minimize "$(get_file mode.main.binding.alt-m)"
check "startup restores saved layouts" \
  "['exec-and-forget \$HOME/.local/bin/omarchy-workspace-layout restore']" "$(get_file after-startup-command)"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
for key in "ALT + L" "ALT + M"; do
  check "overlay lists $key" 1 "$(grep -c "{ \"$key\"," "$LUA")"
done

if pgrep -xq AeroSpace && command -v aerospace >/dev/null; then
  echo "loaded in AeroSpace:"
  for key in alt-f cmd-alt-f cmd-ctrl-f; do
    check "$key is fullscreen below the bar" fullscreen \
      "$(aerospace config --get "mode.main.binding.$key" 2>&1)"
  done
  while read -r ws layout; do
    [[ " ${ALLOW_ACCORDION:-} " == *" $ws "* ]] && continue
    check "workspace $ws root is tiles" tiles "${layout#*_}"
  done < <(aerospace list-workspaces --all --format '%{workspace} %{workspace-root-container-layout}')
else
  echo "loaded in AeroSpace: skipped (AeroSpace not running)"
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
