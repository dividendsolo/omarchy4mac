#!/bin/bash
# Checks Hex as the default dictation (Omarchy 4.5 ships Superwhisper, #28):
# the Brewfile installs Hex, install.sh gives Hex its hold-Right-Option
# shortcut, and Hammerspoon's ⌥Space toggles a dictation through Hex's CLI
# (that block of hammerspoon/init.lua runs under Lua with a stub hs).
# Needs `luajit` (brew install luajit), or `lua`.
#
#   tests/dictation-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
LUA_FILE="${HAMMERSPOON_LUA:-$ROOT/hammerspoon/init.lua}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

LUA_BIN="$(command -v luajit || command -v lua || command -v lua5.4)" ||
  { echo "FAIL: luajit is not installed (brew install luajit)"; exit 1; }

echo "Brewfile:"
check "taps anomalyco/tap" 1 "$(grep -cE '^tap "anomalyco/tap"' "$ROOT/Brewfile")"
check "installs the Hex cask" 1 "$(grep -cE '^cask "anomalyco/tap/hex"' "$ROOT/Brewfile")"
check "FluidVoice is gone" 0 "$(grep -ci fluidvoice "$ROOT/Brewfile")"

echo "install.sh:"
check "hold Right Option dictates" 1 "$(grep -c 'settings set dictation_hotkey right-option' "$ROOT/install.sh")"
check "the shortcut is held, not toggled" 1 "$(grep -c 'settings set shortcut_mode hold' "$ROOT/install.sh")"

# The ⌥Space block between its markers, with hs stubbed to record the binding and the task.
BLOCK="$(sed -n '/^-- dictation: begin/,/^-- dictation: end/p' "$LUA_FILE")"
press() { # what one ⌥Space press runs
  printf '%s\n' "local bound
hs = {
  hotkey = { bind = function(mods, key, fn) bound = { table.concat(mods, '+') .. '-' .. key, fn } end },
  task = { new = function(path, _, args) return { start = function()
    print(bound[1] .. ' ' .. path .. ' ' .. table.concat(args, ' ')) end } end },
}
$BLOCK
bound[2]()" | "$LUA_BIN" - 2>&1
}
echo "Hammerspoon:"
check "⌥Space toggles a Hex dictation" \
  "alt-space /Applications/Hex.app/Contents/MacOS/hex dictation toggle" "$(press)"

# The parity table lives on the docs page now (it moved out of the README when
# the docs site landed, #73).
PARITY="${PARITY:-$HERE/../docs-site/content/docs/parity.mdx}"
echo "The parity page:"
check "the parity table lists dictation as Hex" 1 \
  "$(grep -cE '^\| Voice typing .*\| \[Hex\]\(https://github.com/anomalyco/hex\)' "$PARITY")"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
