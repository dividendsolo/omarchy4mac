#!/bin/bash
# Checks the Omarchy menu's Appearance branch (hammerspoon/init.lua, Omarchy 4.5,
# omacom/omarchy#15973): the root shows Appearance in place of Style, each
# Appearance item opens its chooser, submenu or System Settings pane, and the
# menu search finds every item. init.lua runs in LuaJIT with a stub `hs` that
# records what an item would run, so nothing on the Mac is touched.
#
#   tests/menu-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
command -v luajit >/dev/null || { echo "  FAIL  luajit is not installed (brew install luajit)"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# One cached theme, so the theme chooser opens instead of its "no themes" notice.
mkdir -p "$TMP/.config/theme-switcher/cache/tokyo-night"

HOME="$TMP" luajit - "$LUA" <<'LUAEOF'
local fails = 0
local function check(desc, ok, detail)
  if ok then print("  ok    " .. desc)
  else print("  FAIL  " .. desc .. (detail and (" (" .. detail .. ")") or "")); fails = fails + 1 end
end

-- ---- stub hs: everything is a no-op, except what an item runs ------------
local ran, choosers = {}, {}
local function stub()
  return setmetatable({}, { __index = function() return stub() end, __call = function() return stub() end })
end
hs = stub()
require = function() return stub() end
hs.execute = function(cmd) ran[#ran + 1] = cmd; return "" end
local tasks = {}
hs.task = { new = function(path, _, args)
  ran[#ran + 1] = args[#args]; tasks[#tasks + 1] = { path = path, args = args }
  return stub()
end }
hs.chooser = { new = function(cb)
  local c = { cb = cb, shown = {} }
  function c:choices(list) self.shown = list end
  function c:queryChangedCallback(f) self.query = f end
  function c:placeholderText(p) self.placeholder = p end
  choosers[#choosers + 1] = c
  return setmetatable(c, { __index = function() return function() end end })
end }
dofile(arg[1])

local function texts(rows)
  local t = {}
  for _, r in ipairs(rows) do if not r.back then t[#t + 1] = r.text end end
  return table.concat(t, ", ")
end
-- Pick a row in the open chooser; return what it did.
local function pick(c, row)
  local nRan, nChoosers = #ran, #choosers
  c.cb(row)
  if #choosers > nChoosers then return "chooser:" .. (choosers[#choosers].placeholder or "") end
  return "ran:" .. (ran[nRan + 1] or "nothing")
end

-- ---- root -------------------------------------------------------------------
omarchyMenu()
local root = choosers[#choosers]
local rootText = texts(root.shown)
check("root shows Appearance", (", " .. rootText .. ","):find(", Appearance,", 1, true) ~= nil, rootText)
check("root has no Style", (", " .. rootText .. ","):find(", Style,", 1, true) == nil, rootText)

-- ---- Appearance and what each item opens ----------------------------------
local EXPECT = {
  { "Theme",            "chooser:Pick a theme…" },
  { "Background",       "ran:~/.local/bin/omarchy-cycle-wallpaper" },
  { "Font",             "com.mitchellh.ghostty/config" },
  { "Menu Bar",         "chooser:Appearance › Menu Bar › ", {
      { "Hide or Show",   "sketchybar --bar hidden=toggle" },
      { "Config",         "sketchybar/sketchybarrc" },
      { "macOS Menu Bar", "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension" } } },
  { "Windows",          "chooser:Appearance › Windows › ", {
      { "Gaps",           "aerospace/aerospace.toml" },
      { "Borders",        "borders/bordersrc" } } },
  { "Branding",         "chooser:Appearance › Branding › ", {
      { "Screensaver",    "branding/screensaver.txt" },
      { "About",          "fastfetch" } } },
  { "Dock",             "x-apple.systempreferences:com.apple.Desktop-Settings.extension" },
  { "Workspace Layout", "chooser:Appearance › Workspace Layout › ", {
      { "Tiles / Accordion", "aerospace layout accordion tiles" },
      { "Split Direction",   "aerospace layout tiles horizontal vertical" },
      { "Float / Tile",      "aerospace layout floating tiling" } } },
  { "Animations",       "x-apple.systempreferences:com.apple.Accessibility-Settings.extension" },
  { "Unlock",           "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension" },
  { "Light / Dark",     "x-apple.systempreferences:com.apple.Appearance-Settings.extension" },
  { "Random Theme",     "theme random" },
  { "Sync Themes",      "theme --sync" },
}

local function walk(items, path)
  local names = {}
  for _, e in ipairs(items) do names[#names + 1] = e[1] end
  omarchyMenu(path[1])
  local c = choosers[#choosers]
  for i = 2, #path do -- climb down to the submenu
    for _, r in ipairs(c.shown) do if r.text == path[i] then pick(c, r); break end end
    c = choosers[#choosers]
  end
  local where = table.concat(path, " › ")
  check(where .. " lists " .. table.concat(names, ", "), texts(c.shown) == table.concat(names, ", "), texts(c.shown))
  for _, e in ipairs(items) do
    local row
    for _, r in ipairs(c.shown) do if r.text == e[1] then row = r end end
    if row then
      local did = pick(c, row)
      check(where .. " › " .. e[1] .. " opens " .. e[2], did:find(e[2], 1, true) ~= nil, did)
      if e[3] then
        local sub = { unpack(path) }; sub[#sub + 1] = e[1]
        walk(e[3], sub)
      end
    end
  end
end
walk(EXPECT, { "Appearance" })

-- ---- menu search from the root finds every Appearance item ----------------
local function searchAll(items, path)
  for _, e in ipairs(items) do
    local here = path .. " › " .. e[1]
    if e[3] then searchAll(e[3], here) else
      omarchyMenu()
      local c = choosers[#choosers]
      c.query(e[1]:lower())
      local hit
      for _, r in ipairs(c.shown) do if r.subText == here then hit = r end end
      check("search '" .. e[1]:lower() .. "' finds " .. here, hit ~= nil)
      if hit then
        local did = pick(c, hit)
        check("search hit " .. here .. " opens " .. e[2], did:find(e[2], 1, true) ~= nil, did)
      end
    end
  end
end
searchAll(EXPECT, "Appearance")

-- ---- theme chooser: the name is one argv element, never shell text (#45) --
omarchyMenu("Appearance")
for _, r in ipairs(choosers[#choosers].shown) do if r.text == "Theme" then pick(choosers[#choosers], r); break end end
local evil = "x; touch /tmp/pwned $(id)"
choosers[#choosers].cb({ themeName = evil })
local t = tasks[#tasks]
-- a login shell, like every other menu command: theme needs Homebrew's PATH
-- (sketchybar, nvim, hs) to reload the apps
check("theme chooser runs in a login shell",
  t.path == "/bin/bash" and t.args[1] == "-lc", t.path .. " " .. tostring(t.args[1]))
check("theme chooser script holds no theme name",
  t.args[2] == '~/.local/bin/theme "$1"', tostring(t.args[2]))
check("theme chooser passes the name as one argument ($1)",
  #t.args == 4 and t.args[4] == evil, table.concat(t.args, " | "))

if fails > 0 then print(fails .. " failed"); os.exit(1) end
print("all passed")
LUAEOF
