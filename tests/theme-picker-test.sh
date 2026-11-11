#!/bin/bash
# Checks the theme chooser's delete key (hammerspoon/init.lua, Omarchy 4.5,
# omacom/omarchy#14713): ⌘⌫ on a theme asks first, then runs
# `theme --remove <name>` with the name as one argument and reopens the
# chooser; the current theme and Cancel delete nothing; the key works only
# while the chooser is open. Also checks Trigger > Toggle > Herdr Theme Sync
# (omacom/omarchy#13430). init.lua runs in LuaJIT with a stub `hs`, so
# nothing on the Mac is touched.
#
#   tests/theme-picker-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
command -v luajit >/dev/null || { echo "  FAIL  luajit is not installed (brew install luajit)"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.config/theme-switcher/cache/tokyo-night" "$TMP/.config/theme-switcher/cache/nord" \
         "$TMP/.config/theme-switcher/cache/rose-pine"
echo nord > "$TMP/.config/theme-switcher/current"

HOME="$TMP" luajit - "$LUA" <<'LUAEOF'
local fails = 0
local function check(desc, ok, detail)
  if ok then print("  ok    " .. desc)
  else print("  FAIL  " .. desc .. (detail and (" (" .. detail .. ")") or "")); fails = fails + 1 end
end

local function stub()
  return setmetatable({}, { __index = function() return stub() end, __call = function() return stub() end })
end
hs = stub()
require = function() return stub() end
local ran, tasks, choosers, binds, keys, alerts = {}, {}, {}, {}, {}, {}
hs.execute = function(cmd) ran[#ran + 1] = cmd; return "" end
hs.fs = { attributes = function(p) local f = io.open(p) if f then f:close(); return {} end end }
hs.alert = { show = function(msg) alerts[#alerts + 1] = msg end }
hs.styledtext = { new = function(s) return s end }
hs.task = { new = function(path, cb, args)
  local t = { path = path, args = args, cb = cb }
  tasks[#tasks + 1] = t
  return setmetatable({ start = function() if cb then cb(0, "", "") end end }, { __index = function() return function() end end })
end }
hs.hotkey = {
  bind = function(mods, key, fn) binds[table.concat(mods, "+") .. "+" .. key] = fn; return stub() end,
  new = function(mods, key, fn)
    local k = { id = table.concat(mods, "+") .. "+" .. key, fn = fn, on = false, deleted = false }
    function k:enable() self.on = true; return self end
    function k:disable() self.on = false; return self end
    function k:delete() self.on = false; self.deleted = true end
    keys[#keys + 1] = k
    return k
  end,
}
local answer = "Delete"
local asked = {}
hs.dialog = { blockAlert = function(msg) asked[#asked + 1] = msg; return answer end }
hs.chooser = { new = function(cb)
  local c = { cb = cb, shown = {}, row = 1, visible = false }
  function c:choices(list) self.shown = list end
  function c:showCallback(f) self.onShow = f end
  function c:hideCallback(f) self.onHide = f end
  function c:placeholderText(p) self.placeholder = p end
  function c:selectedRow(n) if n then self.row = n end; return self.row end
  function c:selectedRowContents() return self.shown[self.row] end
  function c:show() self.visible = true; if self.onShow then self.onShow() end end
  function c:isVisible() return self.visible end
  function c:hide() self.visible = false; if self.onHide then self.onHide() end end
  choosers[#choosers + 1] = c
  return setmetatable(c, { __index = function() return function() end end })
end }
dofile(arg[1])

local function delKey()
  for i = #keys, 1, -1 do if keys[i].id == "cmd+delete" and not keys[i].deleted then return keys[i] end end
end
local function open()
  binds["cmd+ctrl+t"]()
  return choosers[#choosers]
end
local function rowOf(c, name)
  for i, r in ipairs(c.shown) do if r.themeName == name then return i end end
end

-- ---- the key exists only while the chooser is open ------------------------
local c = open()
check("the chooser says ⌘⌫ deletes", (c.placeholder or ""):find("⌘⌫", 1, true) ~= nil, c.placeholder)
local k = delKey()
check("⌘⌫ is on while the chooser is open", k ~= nil and k.on)

-- ---- delete a theme ---------------------------------------------------------
c.row = rowOf(c, "tokyo-night")
local nTasks = #tasks
k.fn()
check("asks before deleting", asked[#asked] and asked[#asked]:find("tokyo-night", 1, true) ~= nil, asked[#asked])
local t = tasks[nTasks + 1]
check("runs theme --remove with the name as one argument",
  t ~= nil and t.path:match("/%.local/bin/theme$") ~= nil and t.args[1] == "--remove" and t.args[2] == "tokyo-night" and #t.args == 2,
  t and (t.path .. " " .. table.concat(t.args, " ")) or "no task")
check("the hidden chooser's ⌘⌫ is gone", k.deleted)
local c2 = choosers[#choosers]
check("reopens the chooser after the delete", c2 ~= c and c2.visible)
local after = c2.shown[c2.row] and c2.shown[c2.row].themeName
check("selection lands on the theme before the deleted one", after == "rose-pine" or after == "nord", tostring(after))

-- ---- the current theme is not deleted --------------------------------------
c = choosers[#choosers]; k = delKey()
c.row = rowOf(c, "nord")
nTasks = #tasks
k.fn()
check("the current theme: no delete", #tasks == nTasks)
check("the current theme: says why", alerts[#alerts] and alerts[#alerts]:find("nord", 1, true) ~= nil, alerts[#alerts])

-- ---- Cancel deletes nothing --------------------------------------------------
answer = "Cancel"
c.row = rowOf(c, "rose-pine")
nTasks = #tasks
k.fn()
check("Cancel: no delete", #tasks == nTasks)
answer = "Delete"

-- ---- picking a theme turns the key off ------------------------------------
c = choosers[#choosers]; k = delKey()
c:hide()
check("closing the chooser removes ⌘⌫", k.deleted and not k.on)

-- ---- Trigger > Toggle > Herdr Theme Sync -----------------------------------
omarchyMenu("Trigger")
local m = choosers[#choosers]
local function find(c, text) for _, r in ipairs(c.shown) do if r.text == text then return r end end end
m.cb(find(m, "Toggle"))
m = choosers[#choosers]
local row = find(m, "Herdr Theme Sync")
check("Toggle lists Herdr Theme Sync", row ~= nil)
if row then
  local n = #ran
  m.cb(row)
  check("Herdr Theme Sync turns it on when off", (ran[n + 1] or ""):find("theme --herdr-sync on", 1, true) ~= nil, ran[n + 1])
end

if fails == 0 then print("PASS") else print("FAIL: " .. fails .. " check(s)"); os.exit(1) end
LUAEOF
