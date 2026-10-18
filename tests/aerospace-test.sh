#!/bin/bash
# Checks the AeroSpace rules that keep the desktop Omarchy-like:
# every fullscreen key stays below SketchyBar, and workspaces start in tiles.
# File checks always run; live checks run when AeroSpace is running and read
# the config it actually loaded (so a missing reload fails too).
#
#   tests/aerospace-test.sh
#   AEROSPACE_TOML=/path/to/aerospace.toml tests/aerospace-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

get_file() { # get_file <dotted.key>
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

if pgrep -xq AeroSpace && command -v aerospace >/dev/null; then
  echo "loaded in AeroSpace:"
  for key in alt-f cmd-alt-f cmd-ctrl-f; do
    check "$key is fullscreen below the bar" fullscreen \
      "$(aerospace config --get "mode.main.binding.$key" 2>&1)"
  done
  # A reload does not touch workspaces that already exist; their root keeps
  # the layout it was made with. Every workspace must be in tiles unless the
  # user pressed alt-a there (THEN set ALLOW_ACCORDION=<ws ws ...>).
  while read -r ws layout; do
    [[ " ${ALLOW_ACCORDION:-} " == *" $ws "* ]] && continue
    check "workspace $ws root is tiles" tiles "${layout#*_}"
  done < <(aerospace list-workspaces --all --format '%{workspace} %{workspace-root-container-layout}')
else
  echo "loaded in AeroSpace: skipped (AeroSpace not running)"
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
