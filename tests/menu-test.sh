#!/bin/bash
# Checks the Omarchy menu's Appearance branch (hammerspoon/init.lua, Omarchy 4.5,
# omacom/omarchy#15973): the root shows Appearance in place of Style, each
# Appearance item opens its chooser, submenu or System Settings pane (Window
# Transparency and Window Corners run omarchy-appearance and check the saved
# choice), Trigger has no second Appearance, and the menu search finds every item. init.lua runs in LuaJIT with a stub `hs` that
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
# Update > Config > Hammerspoon checks the file Hammerspoon loads.
mkdir -p "$TMP/.hammerspoon"

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
-- A saved Appearance choice: `omarchy-appearance <what>` (a read) prints it
-- and is not recorded; every other command is recorded as what an item ran.
local SAVED = { transparency = "glassy", corners = "sharp" }
hs.execute = function(cmd)
  local what = cmd:match("omarchy%-appearance (%a+)$")
  if what then return (SAVED[what] or "") .. "\n" end
  ran[#ran + 1] = cmd; return ""
end
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
  function c:rows(n) self.nrows = n end
  -- A chooser counts as on screen only when a check says so (c.open = true).
  function c:isVisible() return self.open == true end
  function c:hide() self.open = false; self.hidden = true end
  choosers[#choosers + 1] = c
  return setmetatable(c, { __index = function() return function() end end })
end }
-- Dimmed text: hs.styledtext.new(s, { color = ... }) keeps the string and records the style.
local styled = {}
hs.styledtext = { new = function(s, attrs) styled[s] = attrs; return s end }
local hotkeys = {}
hs.hotkey = { bind = function(mods, key, fn) hotkeys[table.concat(mods, "+") .. "+" .. key] = fn end }
local reloads = 0
hs.reload = function() reloads = reloads + 1 end
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
  { "Window Transparency", "chooser:Appearance › Window Transparency › ", {
      { "Opaque Windows",      "omarchy-appearance transparency opaque" },
      { "Transparent Windows", "omarchy-appearance transparency transparent" },
      { "Glassy Windows",      "omarchy-appearance transparency glassy" } } },
  { "Window Corners",   "chooser:Appearance › Window Corners › ", {
      { "Theme Corners",       "omarchy-appearance corners theme" },
      { "Sharp Corners",       "omarchy-appearance corners sharp" },
      { "Rounded Corners",     "omarchy-appearance corners rounded" } } },
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

-- ---- the saved Appearance choice carries the check mark --------------------
local function marks(path)
  omarchyMenu(path[1])
  local c = choosers[#choosers]
  for _, r in ipairs(c.shown) do if r.text == path[2] then pick(c, r); break end end
  local m = {}
  for _, r in ipairs(choosers[#choosers].shown) do
    if not r.back and r.subText:sub(1, #"✓ ") == "✓ " then m[#m + 1] = r.text end
  end
  return table.concat(m, ", ")
end
local tm = marks({ "Appearance", "Window Transparency" })
check("Window Transparency checks only the saved Glassy Windows", tm == "Glassy Windows", tm)
local cm = marks({ "Appearance", "Window Corners" })
check("Window Corners checks only the saved Sharp Corners", cm == "Sharp Corners", cm)

-- ---- Install › Service › Slack (Omarchy 4.5, omacom/omarchy#14434) ---------
-- Not installed: installs the cask in Ghostty, then opens Slack.
local slackThere = false
hs.application = stub()
hs.application.launchOrFocus = function(name)
  if name == "Slack" and slackThere then ran[#ran + 1] = "launchOrFocus Slack"; return true end
  return false
end
local SLACK = "brew install --cask slack && open -a Slack"
omarchyMenu("Install")
local inst = texts(choosers[#choosers].shown)
check("Install lists Service", (", " .. inst .. ","):find(", Service,", 1, true) ~= nil, inst)
-- Service holds Microsoft (#32) and Slack, in that order.
local MS = { "Microsoft", "chooser:Install › Service › Microsoft › " }
walk({ MS, { "Slack", SLACK } }, { "Install", "Service" })
searchAll({ { "Slack", SLACK } }, "Install › Service")
-- Installed: the item opens Slack and installs nothing.
slackThere = true
walk({ MS, { "Slack", "ran:launchOrFocus Slack" } }, { "Install", "Service" })

-- ---- Trigger has no second Appearance --------------------------------------
omarchyMenu("Trigger")
local trig = texts(choosers[#choosers].shown)
check("Trigger has no Appearance", (", " .. trig .. ","):find(", Appearance,", 1, true) == nil, trig)

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

-- ---- Microsoft 365 web apps (Omarchy 4.5, #32) ----------------------------
-- Install > Service > Microsoft holds the six; each opens its own app window.
local M365 = {
  { "Outlook",    "omarchy-launch-browser --app=https://outlook.cloud.microsoft/mail/" },
  { "Word",       "omarchy-launch-browser --app=https://word.cloud.microsoft/" },
  { "Excel",      "omarchy-launch-browser --app=https://excel.cloud.microsoft/" },
  { "PowerPoint", "omarchy-launch-browser --app=https://powerpoint.cloud.microsoft/" },
  { "Teams",      "omarchy-launch-browser --app=https://teams.cloud.microsoft/" },
  { "OneDrive",   "omarchy-launch-browser --app=https://onedrive.cloud.microsoft/" },
}
omarchyMenu("Install")
local inst = texts(choosers[#choosers].shown)
check("Install has Service", (", " .. inst .. ","):find(", Service,", 1, true) ~= nil, inst)
slackThere = true   -- Slack installed: the item only opens it
walk({ { "Microsoft", "chooser:Install › Service › Microsoft › ", M365 }, { "Slack", "ran:launchOrFocus Slack" } },
  { "Install", "Service" })
searchAll(M365, "Install › Service › Microsoft")
-- the Apps launcher (⌘⇧Space) has an entry for each
omarchyMenu()
for _, r in ipairs(choosers[#choosers].shown) do if r.text == "Apps" then pick(choosers[#choosers], r); break end end
local appsChooser = choosers[#choosers]
for _, e in ipairs(M365) do
  local row
  for _, r in ipairs(appsChooser.shown) do if r.text == e[1] then row = r end end
  check("Apps launcher has " .. e[1], row ~= nil)
  if row then
    local nRan = #ran
    appsChooser.cb(row)
    local did = ran[nRan + 1] or "nothing"
    check("Apps launcher " .. e[1] .. " opens " .. e[2], did:find(e[2], 1, true) ~= nil, did)
  end
end

-- ---- installed items are dimmed, not hidden (Omarchy 4.5, omacom/omarchy#6955) --
local function serviceRow(name)
  omarchyMenu("Install")
  for _, r in ipairs(choosers[#choosers].shown) do if r.text == "Service" then pick(choosers[#choosers], r); break end end
  for _, r in ipairs(choosers[#choosers].shown) do if r.text == name then return r end end
end
local slackPath
hs.application.pathForBundleID = function(id) return id == "com.tinyspeck.slackmacgap" and slackPath or nil end
slackPath = nil; styled = {}
local row = serviceRow("Slack")
local DIM = "#565f89" -- the palette's comment colour
local function dimmed(s) return styled[s] ~= nil and styled[s].color.hex == DIM end
check("Slack not installed: listed, not dimmed", row ~= nil and styled.Slack ~= nil and not dimmed("Slack")
  and row.subText:sub(1, #"✓") ~= "✓", row and row.subText)
slackPath = "/Applications/Slack.app"; styled = {}
row = serviceRow("Slack")
check("Slack installed: still listed", row ~= nil)
check("Slack installed: dimmed", dimmed("Slack"))
check("Slack installed: marked ✓ installed", row and row.subText == "✓ installed", row and row.subText)
omarchyMenu(); local c = choosers[#choosers]; c.query("slack")
local hit; for _, r in ipairs(c.shown) do if r.subText:find("Install › Service › Slack", 1, true) then hit = r end end
styled = {}; omarchyMenu(); c = choosers[#choosers]; c.query("slack"); hit = nil
for _, r in ipairs(c.shown) do if r.subText:find("Install › Service › Slack", 1, true) then hit = r end end
check("search hit for an installed Slack is dimmed too", hit ~= nil and dimmed("Slack"))

-- ---- every row of a level shows; nothing is cut off (omacom/omarchy#13916) ----
omarchyMenu("Appearance")
c = choosers[#choosers]
check("Appearance shows all " .. #c.shown .. " rows", c.nrows == #c.shown, tostring(c.nrows))
omarchyMenu()
c = choosers[#choosers]
check("root shows all " .. #c.shown .. " rows", c.nrows == #c.shown, tostring(c.nrows))

-- ---- a second press closes the open menu (omacom/omarchy#6725) ----------------
omarchyMenu()
c = choosers[#choosers]; c.open = true
local before = #choosers
omarchyMenu()
check("second omarchyMenu() closes the open menu", c.hidden == true and #choosers == before)
c.open = false
hotkeys["cmd+shift+space"]()
c = choosers[#choosers]; c.open = true; before = #choosers
hotkeys["cmd+shift+space"]()
check("second ⌘⇧Space closes the menu", c.hidden == true and #choosers == before)
for _, key in ipairs({ "alt+k", "cmd+alt+space", "cmd+ctrl+t" }) do
  hotkeys[key]()
  c = choosers[#choosers]; c.open = true; before = #choosers
  hotkeys[key]()
  check("second " .. key .. " closes its chooser", c.hidden == true and #choosers == before)
  c.open = false
end

-- ---- the keybindings overlay leaves no process (omacom/omarchy#7564) ---------
local nRan, nTasks = #ran, #tasks
before = #choosers
hotkeys["alt+k"](); hotkeys["alt+k"]()
check("⌥K runs no command and starts no task", #ran == nRan and #tasks == nTasks)
check("⌥K reuses one chooser", #choosers == before)

-- ---- Update › Config › Hammerspoon keeps the menu on a half-written file (omacom/omarchy#16268) --
local cfg = os.getenv("HOME") .. "/.hammerspoon/init.lua"
local whole = io.open(arg[1]):read("*a")
local function reloadWith(text)
  local f = io.open(cfg, "w"); f:write(text); f:close()
  local n = reloads
  omarchyMenu("Update")
  for _, r in ipairs(choosers[#choosers].shown) do if r.text == "Config" then pick(choosers[#choosers], r); break end end
  for _, r in ipairs(choosers[#choosers].shown) do if r.text == "Hammerspoon" then choosers[#choosers].cb(r); break end end
  return reloads > n
end
check("reload runs on a whole init.lua", reloadWith(whole))
check("reload is refused on a half-written init.lua", not reloadWith(whole:sub(1, math.floor(#whole / 2))))
check("reload is refused on an empty init.lua", not reloadWith(""))

if fails > 0 then print(fails .. " failed"); os.exit(1) end
print("all passed")
LUAEOF
