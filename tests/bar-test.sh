#!/bin/bash
# Checks the Omarchy 4.5 bar polish (#37):
# - scrolling over a workspace item changes workspace (omacom/omarchy#15256);
# - a widget dragged off the bar leaves it, and stays off after a reload
#   (omacom/omarchy#6782): the Hammerspoon drag tap and bin/omarchy-bar-remove;
# - right-click on the clock turns seconds on and off (omacom/omarchy#7586);
# - the clock writes nothing to the log across the end of daylight saving time
#   (omacom/omarchy#16684).
# sketchybar, aerospace and open are stubs on PATH, and init.lua runs in LuaJIT
# with a stub `hs`, so the running bar and desktop are never touched.
#
#   tests/bar-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config/plugins" "$TMP/home"
printf 'export FG="0xfffffff0"\nexport MAGENTA="0xffff00ff"\nexport BG="0xff000000"\nexport BLUE="0xff0000ff"\n' > "$TMP/config/colors.sh"
cp "$ROOT/sketchybar/plugins/displays.sh" "$TMP/config/plugins/"
export CONFIG_DIR="$TMP/config" HOME="$TMP/home" LOG="$TMP/log"

# sketchybar stub: answers the display query and the item queries from
# $TMP/q/<name>.json, and logs every other call.
mkdir -p "$TMP/q"
cat > "$TMP/bin/sketchybar" <<'STUB'
#!/bin/bash
if [[ "$1" == "--query" ]]; then
  [[ "$2" == displays ]] && { echo '[{"arrangement-id": 1, "DirectDisplayID": 0}]'; exit 0; }
  cat "$(dirname "$0")/../q/$2.json"; exit 0
fi
echo "sketchybar $*" >> "$LOG"
STUB
for tool in aerospace open; do printf '#!/bin/bash\necho "%s $*" >> "$LOG"\n' "$tool" > "$TMP/bin/$tool"; done
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:$PATH"

check() { # check <description> <expected substring> <actual>
  if [[ "$3" == *"$2"* ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2' in '$3')"; fails=$((fails + 1)); fi
}
check_not() { # check_not <description> <unexpected substring> <actual>
  if [[ "$3" != *"$2"* ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (did not expect '$2' in '$3')"; fails=$((fails + 1)); fi
}
log() { cat "$LOG" 2>/dev/null; }

echo "workspace scroll:"
rc="$(cat "$ROOT/sketchybar/sketchybarrc")"
check "workspace items listen for the wheel" "--subscribe space.\"\$sid\" aerospace_workspace_change mouse.scrolled" "$rc"
: > "$LOG"; NAME=space.2 SENDER=mouse.scrolled SCROLL_DELTA=3 bash "$ROOT/sketchybar/plugins/aerospace.sh"
check "wheel up goes to the workspace before" "aerospace workspace prev" "$(log)"
: > "$LOG"; NAME=space.2 SENDER=mouse.scrolled SCROLL_DELTA=-3 bash "$ROOT/sketchybar/plugins/aerospace.sh"
check "wheel down goes to the workspace after" "aerospace workspace next" "$(log)"
check_not "a scroll does not repaint the item" "sketchybar" "$(log)"

echo "clock seconds:"
SEC="$HOME/.config/omarchy/clock-seconds"
clock() { : > "$LOG"; NAME=clock "$@" bash "$ROOT/sketchybar/plugins/clock.sh" 2> "$TMP/err"; log; }
NOON=1794423600 # 2026-11-11 14:00:00 EST
out="$(clock env TZ=America/New_York SENDER=forced CLOCK_NOW=$NOON)"
check "seconds off: hours and minutes" 'label=Wed  2:00 PM' "$out"
check "seconds off: a tick every 10 s" "update_freq=10" "$out"
out="$(clock env TZ=America/New_York SENDER=mouse.clicked BUTTON=right CLOCK_NOW=$NOON)"
check "right-click turns seconds on" 'label=Wed  2:00:00 PM' "$out"
check "seconds on: a tick every second" "update_freq=1" "$out"
[[ -e "$SEC" ]] && echo "  ok    the choice is saved" || { echo "  FAIL  the choice is saved"; fails=$((fails + 1)); }
out="$(clock env TZ=America/New_York SENDER=routine CLOCK_NOW=$((NOON + 7)))"
check "seconds on: the time moves every second" 'label=Wed  2:00:07 PM' "$out"
out="$(clock env TZ=America/New_York SENDER=mouse.clicked BUTTON=right CLOCK_NOW=$NOON)"
check "right-click again turns seconds off" 'label=Wed  2:00 PM' "$out"
[[ ! -e "$SEC" ]] && echo "  ok    the choice is cleared" || { echo "  FAIL  the choice is cleared"; fails=$((fails + 1)); }
out="$(clock env TZ=America/New_York SENDER=mouse.clicked BUTTON=left CLOCK_NOW=$NOON)"
check "left-click still opens Date & Time" "open x-apple.systempreferences:com.apple.Date-Time-Settings.extension" "$out"
check "both clocks take the clicks" "--subscribe clock display_change mouse.clicked" "$rc"
check "the right clock runs the same script" "--subscribe clock_right mouse.clicked" "$rc"

echo "clock across the end of daylight saving (2026-11-01, New York):"
touch "$SEC"
# 01:59:59 EDT, 01:00:00 EST (the hour repeats), 01:30 EST, 02:00 EST
for t in 1793512799:'1:59:59 AM' 1793512800:'1:00:00 AM' 1793514600:'1:30:00 AM' 1793516400:'2:00:00 AM'; do
  for sender in routine forced; do
    out="$(clock env TZ=America/New_York SENDER=$sender CLOCK_NOW="${t%%:*}")"
    check "$sender at ${t#*:}: the right time" "label=Sun  ${t#*:}" "$out"
    [[ ! -s "$TMP/err" ]] || { echo "  FAIL  $sender at ${t#*:}: stderr: $(cat "$TMP/err")"; fails=$((fails + 1)); }
    n="$(grep -c . "$LOG")"; (( n <= 3 )) && echo "  ok    $sender at ${t#*:}: $n bar call(s)" \
      || { echo "  FAIL  $sender at ${t#*:}: $n bar calls"; fails=$((fails + 1)); }
  done
done
rm -f "$SEC"

echo "omarchy-bar-remove:"
REMOVE="$ROOT/bin/omarchy-bar-remove"
LIST="$HOME/.config/omarchy/bar-removed"
item_json() { # item_json <name> <drawing> <position> <x> <w>
  printf '{"name":"%s","geometry":{"drawing":"%s","position":"%s"},"bounding_rects":{"display-1":{"origin":[%s,0.0],"size":[%s,32.0]},"display-2":{"origin":[-9999.0,-9999.0],"size":[24.0,32.0]}}}' "$@"
}
bar_json() { printf '{"hidden":"%s","items":["logo","clock","weather","bar_removed","media"]}' "$1"; }
bar_json off > "$TMP/q/bar.json"
item_json logo on left 0 40 > "$TMP/q/logo.json"
item_json clock on center 790 129 > "$TMP/q/clock.json"
item_json weather off center 920 60 > "$TMP/q/weather.json"
item_json bar_removed off left 0 0 > "$TMP/q/bar_removed.json"
item_json media on popup.bar_removed 790 129 > "$TMP/q/media.json"
: > "$LOG"; bash "$REMOVE" 800.5 10
check "the item under the drag goes into the hidden popup" "sketchybar --set clock position=popup.bar_removed" "$(log)"
check "the item is remembered" "clock" "$(cat "$LIST" 2>/dev/null)"
: > "$LOG"; bash "$REMOVE" 950 10
check_not "a hidden item is not removed" "--set" "$(log)"
: > "$LOG"; bash "$REMOVE" 1500 10
check_not "empty bar: nothing is removed" "--set" "$(log)"
bar_json on > "$TMP/q/bar.json"
: > "$LOG"; bash "$REMOVE" 5 10
check_not "bar hidden: nothing is removed" "--set" "$(log)"
bash "$REMOVE" 'x;rm' 10 2>/dev/null && { echo "  FAIL  a bad point is refused"; fails=$((fails + 1)); } || echo "  ok    a bad point is refused"
check "sketchybarrc keeps the removed items off after a reload" 'position=popup.bar_removed' "$rc"
: > "$LOG"; bash "$REMOVE" --reset
check "--reset reloads the bar" "sketchybar --reload" "$(log)"
[[ ! -e "$LIST" ]] && echo "  ok    --reset forgets the removed items" || { echo "  FAIL  --reset forgets the removed items"; fails=$((fails + 1)); }

echo "drag off the bar (hammerspoon/init.lua):"
if ! command -v luajit >/dev/null; then echo "  FAIL  luajit is not installed (brew install luajit)"; fails=$((fails + 1))
else
out="$(luajit - "$ROOT/hammerspoon/init.lua" <<'LUAEOF'
local function stub()
  return setmetatable({}, { __index = function() return stub() end, __call = function() return stub() end })
end
local mt = { __index = function() return stub() end }
hs = stub()
hs.execute = function() return "" end
require = function() return stub() end
local taps, tasks = {}, {}
local T = { leftMouseDown = "down", leftMouseUp = "up" }
hs.eventtap = setmetatable({
  event = setmetatable({ types = setmetatable(T, mt) }, mt),
  new = function(types, fn)
    if types[1] == T.leftMouseDown then taps[#taps + 1] = fn end
    return setmetatable({ start = function(self) return self end }, mt)
  end,
}, mt)
-- Two screens side by side, the second one taller.
local screens = { { x = 0, y = 0, w = 1512, h = 982 }, { x = 1512, y = -200, w = 2560, h = 1440 } }
hs.screen = setmetatable({ allScreens = function()
  local out = {}
  for _, f in ipairs(screens) do out[#out + 1] = { fullFrame = function() return f end } end
  return out
end }, mt)
hs.task = { new = function(path, _, args) tasks[#tasks + 1] = path .. " " .. table.concat(args, " "); return stub() end }
dofile(arg[1])
local function drag(x1, y1, x2, y2)
  for _, fn in ipairs(taps) do
    fn({ getType = function() return "down" end, location = function() return { x = x1, y = y1 } end })
    fn({ getType = function() return "up" end, location = function() return { x = x2, y = y2 } end })
  end
  local t = tasks[#tasks] or "nothing"; tasks = {}; return t
end
print("taps=" .. #taps)
print("off=" .. drag(800, 10, 820, 200))
print("short=" .. drag(800, 10, 800, 60))
print("below=" .. drag(800, 100, 800, 400))
print("second=" .. drag(2000, -190, 2000, -100))
LUAEOF
)"
check "init.lua watches mouse down and up" "taps=1" "$out"
check "a drag well below the bar removes the item it started on" "off=$HOME/.local/bin/omarchy-bar-remove 800 10" "$out"
check "a short pull removes nothing" "short=nothing" "$out"
check "a drag that starts below the bar removes nothing" "below=nothing" "$out"
check "the bar on a second screen counts from that screen's top" "second=$HOME/.local/bin/omarchy-bar-remove 2000 -190" "$out"
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
