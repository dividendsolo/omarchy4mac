#!/bin/bash
# Checks the Quake-style agent console (Omarchy 4.5, Super + Grave, #27):
# the panel geometry in hammerspoon/init.lua, run under Lua, and the wiring
# (Hammerspoon owns ⌘` and ⌘⇧`, AeroSpace no longer binds them, and a new
# console starts the default agent). Needs `lua` (brew install lua).
#
#   tests/console-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LUA_FILE="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

LUA_BIN="$(command -v lua || command -v luajit || command -v lua5.4)" ||
  { echo "FAIL: lua is not installed (brew install lua)"; exit 1; }

# consoleFrame is a pure function between two marker lines; run that exact code.
FN="$(sed -n '/^-- console-frame: begin/,/^-- console-frame: end/p' "$LUA_FILE")"
frame() { # frame <x> <y> <w> <h> -> "x y w h" of the console panel
  # On stdin, not -e: PUC Lua reads an -e chunk that starts with "--" as an option.
  printf '%s\n' "$FN
local f = consoleFrame({ x = $1, y = $2, w = $3, h = $4 })
print(string.format('%d %d %d %d', f.x, f.y, f.w, f.h))" | "$LUA_BIN" - 2>&1
}

echo "console geometry:"
check "wide screen: centered 2:1 panel on the top half" "500 0 1000 500" "$(frame 0 0 2000 1000)"
check "narrow screen: full width, top half" "0 0 800 600" "$(frame 0 0 800 1200)"
check "second screen: placed in that screen's frame" "2060 25 1000 500" "$(frame 1560 25 2000 1000)"

echo "wiring:"
binds() { grep -cE "hs\.hotkey\.bind\(\{ *$1 *\}, *\"\`\"" "$LUA_FILE"; }
check "Hammerspoon binds ⌘\`" 1 "$(binds '"cmd"')"
check "Hammerspoon binds ⌘⇧\`" 1 "$(binds '"cmd", *"shift"')"
check "AeroSpace does not bind cmd-backtick" 0 "$(grep -cE '^cmd-backtick *=' "$TOML")"
check "AeroSpace does not bind cmd-shift-backtick" 0 "$(grep -cE '^cmd-shift-backtick *=' "$TOML")"
check "a new console starts the default agent" 1 \
  "$(grep -c 'open -na Ghostty --args -e \$HOME/.local/bin/omarchy-agent' "$LUA_FILE")"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
