#!/bin/bash
# Checks that nothing on the bar is drawn under the notch of a MacBook's
# built-in screen (#70): every left item ends before the notch, every right
# item fits between the notch and the screen's right edge, and no centre item
# draws there. The real sketchybarrc and the agents, clock and bluetooth
# plugins run against a stub sketchybar that logs every call, with the
# built-in screen as arrangement 3 and two external screens as 1 and 2. The
# log is then laid out with the widths in tests/fixtures/notch.json (measured
# on the live bar; the notch from NSScreen.auxiliaryTop*Area), so the test
# runs on a Mac without a notch, and without SketchyBar, too.
#
#   tests/notch-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
FIXTURE="$HERE/fixtures/notch.json"
fails=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/repo/bin" "$TMP/home/.config/theme-switcher" "$TMP/home/.config/omarchy"
cp -R "$ROOT/sketchybar" "$TMP/repo/sketchybar"
CONFIG="$TMP/repo/sketchybar"
printf 'export FG=0xffffffff ACCENT=0xff00ff00 MAGENTA=0xffff00ff BLUE=0xff0000ff CYAN=0xff00ffff YELLOW=0xffffff00 GREEN=0xff00ff00 COMMENT=0xff888888 SURFACE=0xff222222 BG=0xff000000 BG_TRANS=0xcc000000\n' > "$CONFIG/colors.sh"
# The display lookup: built-in is arrangement 3, the externals 1 and 2.
{ echo 'BUILTIN=3; OTHERS=1,2; DISPLAYS_OK=1'
  sed -n '/^center_item()/,/^}/p' "$ROOT/sketchybar/plugins/displays.sh"; } > "$CONFIG/plugins/displays.sh"
fixture() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["worst"][sys.argv[2]])' "$FIXTURE" "$1"; }
fixture theme > "$TMP/home/.config/theme-switcher/current"

# sketchybar logs each call as one JSON array; queries answer empty.
cat > "$TMP/bin/sketchybar" <<'STUB'
#!/bin/bash
[ "$1" = --query ] && { echo '{}'; exit 0; }
python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "$@" >> "$NOTCH_TEST_LOG"
STUB
for tool in aerospace osascript networksetup; do printf '#!/bin/bash\n' > "$TMP/bin/$tool"; done
# Claude signed in at its widest; Codex and Grok signed out.
cat > "$TMP/repo/bin/omarchy-agent-usage" <<STUB
#!/bin/bash
[ "\$1" = claude ] || exit 1
echo '$(fixture claude)'
STUB
chmod +x "$TMP/bin/"* "$TMP/repo/bin/"*
export PATH="$TMP/bin:$PATH" HOME="$TMP/home" CONFIG_DIR="$CONFIG" NOTCH_TEST_LOG="$TMP/log"
export MEDIA_CONTROL="$TMP/none"

bar() { # bar: build the bar and run the plugins whose items move per screen
  : > "$TMP/log"
  bash "$CONFIG/sketchybarrc" >/dev/null 2>&1
  for item in agents.claude agents.codex agents.grok bluetooth wifi; do
    NAME="$item" bash "$CONFIG/plugins/${item%%.*}.sh" >/dev/null 2>&1
  done
  NAME=clock CLOCK_NOW=1794423600 bash "$CONFIG/plugins/clock.sh" >/dev/null 2>&1
}

layout() { # layout <case>: one line per item drawn in the wrong place, then "ok"
  python3 - "$FIXTURE" "$TMP/log" "$1" <<'PY'
import json, sys
f = json.load(open(sys.argv[1])); case = sys.argv[3]; worst = f["worst"]
items, order, default = {}, {"left": [], "right": [], "center": []}, {}
for call in map(json.loads, open(sys.argv[2])):
    i = 0
    while i < len(call):
        word = call[i]
        if word == "--add" and call[i + 1] == "item":
            name, pos = call[i + 2], call[i + 3]
            items[name] = dict(default); order[pos].append(name); i += 4; continue
        target = None
        if word == "--set": target = items.setdefault(call[i + 1], {}); i += 2
        elif word == "--default": target = default; i += 1
        else: i += 1; continue
        while i < len(call) and not call[i].startswith("--"):
            k, _, v = call[i].partition("="); target[k] = v; i += 1

# The day at its widest: a Friday with the stand-up timer, music, a long app name.
for name, label in (("standup", None), ("sunset", worst["sunset"]), ("media", worst["media"]),
                    ("media_next", None), ("front_app", worst["front_app"])):
    items[name]["drawing"] = "on"
    if label: items[name]["label"] = label
items["battery"]["label"] = worst["battery"] + "%"
items["volume"]["label"] = worst["volume"] + "%"

def on_builtin(name):
    p = items[name]
    if p.get("drawing") == "off" or p.get("position", "").startswith("popup"): return False
    shown = p.get("associated_display")
    return shown is None or "3" in shown.split(",")

def width(name):
    p = items[name]
    if name in f["fixed"]: return f["fixed"][name]
    label = p.get("label", "") if p.get("label.drawing") != "off" else ""
    chars = min(len(label), int(p.get("label.max_chars", 10**6)))
    return f["overhead"][name] + chars * f["label_char_width"]

W, pad, gap = f["screen_width"], f["bar_padding"], f["item_padding"]
notch_left, notch_right = f["auxiliary_top_left_width"], W - f["auxiliary_top_right_width"]
x = pad
for name in filter(on_builtin, order["left"]):
    start, end = x + gap, x + gap + width(name); x = end + gap
    if end > notch_left: print("%s: left item runs under the notch (x %.1f-%.1f, notch from %.1f)" % (name, start, end, notch_left))
x = W - pad
for name in filter(on_builtin, order["right"]):
    end, start = x - gap, x - gap - width(name); x = start - gap
    if start < notch_right: print("%s: right item runs under the notch (x %.1f-%.1f, notch to %.1f)" % (name, start, end, notch_right))
for name in filter(on_builtin, order["center"]):
    print("%s: centre item drawn on the notched screen" % name)
print("ok")
PY
}

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1:"; sed 's/^/          /' <<<"$3"; fails=$((fails + 1)); fi
}

echo "notched built-in screen:"
bar
check "nothing under the notch" "ok" "$(layout plain)"
claude="$(python3 -c '
import json,sys
for call in map(json.loads, open(sys.argv[1])):
    if "--set" in call and call[call.index("--set") + 1] == sys.argv[2]:
        print(" ".join(a for a in call if a.startswith(("associated_display=", "label=")) or a == "drawing=off"))' "$TMP/log" agents_notch.claude | tail -1)"
check "the Claude limits read in short form there" "associated_display=3 label=100% · 100%" "$claude"
touch "$HOME/.config/omarchy/clock-seconds"; bar
check "nothing under the notch with the clock's seconds on" "ok" "$(layout seconds)"
rm -f "$HOME/.config/omarchy/clock-seconds"

echo "external screens:"
full="$(python3 -c '
import json,sys
for call in map(json.loads, open(sys.argv[1])):
    if "--set" in call and call[call.index("--set") + 1] == "agents.claude":
        print(" ".join(a for a in call if a.startswith(("associated_display=", "label="))))' "$TMP/log" | tail -1)"
check "the Claude limits keep the full label" "associated_display=1,2 label=$(fixture claude)" "$full"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
