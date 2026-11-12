#!/bin/bash
# Checks the Omarchy 4.5 keybinding changes (#31): every moved key does its new
# job, the old key does nothing or its new job, the new default keys exist, and
# the ⌥K overlay lists the new table. AeroSpace keys are read from
# aerospace.toml; Hammerspoon keys run in LuaJIT with a stub `hs` that records
# what a key would run, so nothing on the Mac is touched.
#
#   tests/keys-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

key() { # key <aerospace key> -> its main-mode command, or "" when unbound
  python3 - "$TOML" "$1" <<'PY'
import sys, tomllib
print(tomllib.load(open(sys.argv[1], "rb"))["mode"]["main"]["binding"].get(sys.argv[2], ""))
PY
}

echo "aerospace.toml, moved keys:"
check "⌘⇧Q opens Calculator" 'exec-and-forget open -a Calculator' "$(key cmd-shift-q)"
check "⌥⇧T opens Activity (btop)" 'exec-and-forget open -na Ghostty --args -e btop' "$(key alt-shift-t)"
check "⌘⇧T stays the browser's reopen-tab key" '' "$(key cmd-shift-t)"
check "⌘⌃T is left to Hammerspoon (themes)" '' "$(key cmd-ctrl-t)"
check "⌘⌃N opens Network settings" \
  'exec-and-forget open "x-apple.systempreferences:com.apple.wifi-settings-extension"' "$(key cmd-ctrl-n)"
check "⌘⌃W is left to Hammerspoon (backgrounds)" '' "$(key cmd-ctrl-w)"
check "⌘⌃, no longer toggles Do Not Disturb" '' "$(key cmd-ctrl-comma)"
check "⌘⌃⌥, toggles Do Not Disturb" 'exec-and-forget shortcuts run "Toggle Do Not Disturb"' "$(key cmd-ctrl-alt-comma)"
echo "aerospace.toml, new defaults:"
check "⌥Q closes like ⌥W" "$(key alt-w)" "$(key alt-q)"
check "⌘⌥L cycles the workspace layout back" \
  'exec-and-forget $HOME/.local/bin/omarchy-workspace-layout back' "$(key cmd-alt-l)"
check "⌘⌃⌥C takes a screenshot (⇧⌘4)" \
  "exec-and-forget osascript -e 'tell application \"System Events\" to key code 21 using {command down, shift down}'" \
  "$(key cmd-ctrl-alt-c | sed 's/ *$//')"
check "⌘⌃⌥E opens the world clock" 'exec-and-forget open -a Clock' "$(key cmd-ctrl-alt-e)"
check "⌘⌃⌥F toggles the full screen desktop" \
  'exec-and-forget /opt/homebrew/bin/sketchybar --bar hidden=toggle' "$(key cmd-ctrl-alt-f)"

# The parity table lives on the docs page now (it moved out of the README when
# the docs site landed, #73).
PARITY="${PARITY:-$HERE/../docs-site/content/docs/parity.mdx}"
echo "the parity page's table:"
check "the bar hide/show row names ⌘⌃⌥F" 1 \
  "$(grep -E '^\| Bar hide/show key ' "$PARITY" | grep -F 'sketchybar --bar hidden=toggle' | grep -cF '⌘⌃⌥F')"
check "no line puts the bar toggle on ⌘⇧Space" 0 \
  "$(grep -E 'hidden=toggle|[Bb]ar hide' "$PARITY" | grep -c '⌘⇧Space')"

command -v luajit >/dev/null || { echo "  FAIL  luajit is not installed (brew install luajit)"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.config/theme-switcher/cache/tokyo-night"

echo "hammerspoon/init.lua:"
HOME="$TMP" luajit - "$LUA" <<'LUAEOF' || fails=$((fails + 1))
local fails = 0
local function check(desc, ok, detail)
  if ok then print("  ok    " .. desc)
  else print("  FAIL  " .. desc .. (detail and (" (" .. tostring(detail) .. ")") or "")); fails = fails + 1 end
end

-- ---- stub hs: no-ops, except binds, commands and choosers -----------------
local ran, choosers, binds = {}, {}, {}
local function stub()
  return setmetatable({}, { __index = function() return stub() end, __call = function() return stub() end })
end
hs = stub()
require = function() return stub() end
hs.execute = function(cmd) ran[#ran + 1] = cmd; return "" end
hs.task = { new = function(_, _, args) ran[#ran + 1] = args[#args]; return stub() end }
hs.chooser = { new = function(cb)
  local c = { cb = cb, shown = {} }
  function c:choices(list) self.shown = list end
  function c:placeholderText(p) self.placeholder = p end
  choosers[#choosers + 1] = c
  return setmetatable(c, { __index = function() return function() end end })
end }
hs.hotkey = { bind = function(mods, key, fn)
  table.sort(mods)
  binds[table.concat(mods, "+") .. "+" .. key] = fn
  return stub()
end, new = function() return stub() end } -- new: the theme chooser's ⌘⌫, live only while it is open
-- Notification Center: a window holding a stack of two banners, newest first.
local pressed = {}
local function el(name, subrole, children)
  return { name = name,
    attributeValue = function(self, a)
      if a == "AXSubrole" then return subrole end
      if a == "AXChildren" then return children end
    end,
    performAction = function(self, a) pressed[#pressed + 1] = self.name .. ":" .. a end }
end
local tree = el("app", nil, { el("window", nil, { el("stack", "AXNotificationCenterAlertStack", {
  el("newest", "AXNotificationCenterBanner", {}), el("older", "AXNotificationCenterBanner", {}) }) }) })
hs.application = setmetatable({ get = function(id)
  if id == "com.apple.notificationcenterui" then return {} end
end }, { __index = function() return stub() end })
hs.axuielement = { applicationElement = function() return tree end }
dofile(arg[1])

-- Press a chord; return what it did.
local function press(chord)
  local fn = binds[chord]
  if not fn then return "unbound" end
  local nRan, nChoosers = #ran, #choosers
  fn()
  if #choosers > nChoosers then return "chooser:" .. (choosers[#choosers].placeholder or "") end
  return "ran:" .. (ran[nRan + 1] or "nothing")
end

check("⌘⌃T opens the theme chooser", press("cmd+ctrl+t"):find("chooser:Pick a theme…", 1, true) == 1, press("cmd+ctrl+t"))
local w = press("cmd+ctrl+w")
check("⌘⌃W switches to the next background", w:find("omarchy-cycle-wallpaper", 1, true) ~= nil, w)
check("⌘⌥Space opens Apps", press("alt+cmd+space") == "chooser:Launch…", press("alt+cmd+space"))
check("⌘⇧Space opens the Omarchy menu", press("cmd+shift+space") == "chooser:Omarchy…", press("cmd+shift+space"))
check("⌘⌃Q is not bound (Calculator moved to ⌘⇧Q)", binds["cmd+ctrl+q"] == nil)

press("alt+,")
check("⌥, presses the newest notification", table.concat(pressed, ",") == "newest:AXPress", table.concat(pressed, ","))
pressed = {}
tree = el("app", nil, { el("window", nil, {}) })
local ok, err = pcall(press, "alt+,")
check("⌥, with no notification on screen does nothing", ok and #pressed == 0, err or table.concat(pressed, ","))

-- ---- the ⌥K overlay -------------------------------------------------------
press("alt+k")
local overlay = {}
for _, r in ipairs(choosers[#choosers].shown) do overlay[r.text] = r.subText end
local ROWS = {
  { "SUPER + SHIFT + Q",        "Calculator" },
  { "ALT + SHIFT + T",          "Activity" },
  { "SUPER + CTRL + T",         "Theme" },
  { "SUPER + CTRL + N",         "Network" },
  { "SUPER + CTRL + W",         "background" },
  { "SUPER + ALT + SPACE",      "Apps" },
  { "SUPER + SHIFT + SPACE",    "Omarchy" },
  { "ALT + ,",                  "newest notification" },
  { "SUPER + CTRL + ALT + ,",   "Do Not Disturb" },
  { "ALT + Q",                  "Quit" },
  { "SUPER + ALT + L",          "back" },
  { "SUPER + CTRL + ALT + C",   "Screenshot" },
  { "SUPER + CTRL + ALT + E",   "World clock" },
  { "SUPER + CTRL + ALT + F",   "Full screen desktop" },
}
for _, row in ipairs(ROWS) do
  local sub = overlay[row[1]]
  check("overlay: " .. row[1] .. " is " .. row[2], sub ~= nil and sub:find(row[2], 1, true) ~= nil, sub or "missing")
end
check("overlay has no SUPER + CTRL + , row", overlay["SUPER + CTRL + ,"] == nil, overlay["SUPER + CTRL + ,"])

if fails > 0 then print(fails .. " failed"); os.exit(1) end
LUAEOF

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
