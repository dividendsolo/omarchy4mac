#!/bin/bash
# Checks per-monitor workspaces (Omarchy 4.5): the number keys pick the focused
# monitor's own workspaces, and unplugging a monitor renumbers nothing.
# aerospace is a stub on PATH, so the running window manager is never touched.
#
#   tests/workspace-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../bin/omarchy-workspace"
TOML="$HERE/../aerospace/aerospace.toml"
fails=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/aerospace" <<'STUB'
#!/bin/bash
touch "$WS_TEST_LOG.stub"
case "$1 ${2:-}" in
  "config --config-path") echo "$WS_TEST_TOML" ;;
  "list-monitors --focused") echo "$WS_TEST_MONITOR" ;;
  "list-workspaces --monitor") printf '%s\n' $WS_TEST_WORKSPACES ;;
  *) echo "$*" >> "$WS_TEST_LOG" ;;
esac
STUB
chmod +x "$TMP/bin/aerospace"

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

run() { # run <monitor name> <workspaces on it> <args...>: prints the aerospace calls, one per line joined by ' ; '
  : > "$TMP/log"
  PATH="$TMP/bin:$PATH" WS_TEST_TOML="$TOML" WS_TEST_MONITOR="$1" WS_TEST_WORKSPACES="$2" \
    WS_TEST_LOG="$TMP/log" bash "$SCRIPT" "${@:3}"
  paste -sd';' "$TMP/log" | sed 's/;/ ; /g'
}

echo "omarchy-workspace:"
check "right monitor: 1 is its first workspace" "workspace 2" "$(run 'VA2446 (2)' '2 3' 1)"
check "right monitor: 2 is its second workspace" "workspace 3" "$(run 'VA2446 (2)' '2 3' 2)"
check "right monitor: 3 does not leave the monitor" "" "$(run 'VA2446 (2)' '2 3' 3)"
check "laptop: 1 is workspace 4" "workspace 4" "$(run 'Built-in Retina Display' '4 5' 1)"
# Both externals unplugged: the laptop keeps 4 and 5 as its 1 and 2, and the
# guests from the externals come after them.
check "externals unplugged: laptop keeps 1 = workspace 4" "workspace 4" "$(run 'Built-in Retina Display' '1 2 3 4 5' 1)"
check "externals unplugged: laptop keeps 2 = workspace 5" "workspace 5" "$(run 'Built-in Retina Display' '1 2 3 4 5' 2)"
check "externals unplugged: guests come after" "workspace 1" "$(run 'Built-in Retina Display' '1 2 3 4 5' 3)"
check "laptop closed: right keeps 1 = workspace 2" "workspace 2" "$(run 'VA2446 (2)' '2 3 4 5' 1)"
check "laptop closed: guests come after" "workspace 4" "$(run 'VA2446 (2)' '2 3 4 5' 3)"
check "a bad number does nothing" "" "$(run 'VA2446 (2)' '2 3' 'x' 2>/dev/null)"
check "--move sends the window, focus stays" "move-node-to-workspace 5" "$(run 'Built-in Retina Display' '4 5' --move 2)"
check "--move-follow sends the window and follows" "move-node-to-workspace 5 ; workspace 5" \
  "$(run 'Built-in Retina Display' '4 5' --move-follow 2)"

# A Mac has the real aerospace in /opt/homebrew/bin: the script must still run
# the stub. A copy of the script points that dir at a decoy that only leaves a mark.
mkdir -p "$TMP/brew"
printf '#!/bin/bash\ntouch "%s/decoy"\n' "$TMP" > "$TMP/brew/aerospace"
chmod +x "$TMP/brew/aerospace"
sed "s#/opt/homebrew/bin#$TMP/brew#" "$SCRIPT" > "$TMP/omarchy-workspace"
rm -f "$TMP/log.stub" "$TMP/decoy"
SCRIPT="$TMP/omarchy-workspace" run 'VA2446 (2)' '2 3' 1 >/dev/null
check "the stub is the aerospace that ran" "stub" "$( [[ -e $TMP/log.stub ]] && echo stub)$( [[ -e $TMP/decoy ]] && echo ' decoy')"

echo "aerospace.toml:"
python3 - "$TOML" <<'PY' || fails=$((fails + 1))
import re, sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
b = d["mode"]["main"]["binding"]
assign = d["workspace-to-monitor-force-assignment"]
bad = 0
def check(desc, want, got):
    global bad
    ok = want == got
    print(f"  {'ok   ' if ok else 'FAIL '} {desc}" + ("" if ok else f" (expected {want!r}, got {got!r})"))
    bad += not ok
for n in "12345":
    check(f"alt-{n} picks the focused monitor's workspace", f"exec-and-forget $HOME/.local/bin/omarchy-workspace {n}", b[f"alt-{n}"])
    check(f"cmd-shift-{n} moves and follows on this monitor", f"exec-and-forget $HOME/.local/bin/omarchy-workspace --move-follow {n}", b[f"cmd-shift-{n}"])
    check(f"cmd-shift-alt-{n} moves on this monitor", f"exec-and-forget $HOME/.local/bin/omarchy-workspace --move {n}", b[f"cmd-shift-alt-{n}"])
for k in ("left", "down", "up", "right"):
    check(f"cmd-{k} crosses to the neighbouring display", f"focus --boundaries all-monitors-outer-frame {k}", b[f"cmd-{k}"])
check("alt-tab cycles the focused monitor's workspaces", "workspace --wrap-around next", b["alt-tab"])
check("cmd-ctrl-tab keeps back-and-forth", "workspace-back-and-forth", b["cmd-ctrl-tab"])

def place(monitors):  # where AeroSpace puts each workspace: first pattern that matches a monitor
    out = {}
    for ws, pats in assign.items():
        pats = [pats] if isinstance(pats, str) else pats
        out[ws] = next((m for p in pats for m in monitors if re.search(p, m, re.I)), None)
    return out
L, R, B = "VA2446 (1)", "VA2446 (2)", "Built-in Retina Display"
full = place([L, R, B])
check("all plugged in: 1 left, 2-3 right, 4-5 laptop", {"1": L, "2": R, "3": R, "4": B, "5": B}, full)
# macOS drops the (1)/(2) suffix once the twin is gone.
check("left unplugged: 2-3 stay on the right, 4-5 on the laptop",
      ("VA2446", "VA2446", B, B), tuple(place(["VA2446", B])[w] for w in "2345"))
check("right unplugged: 1 stays on the left, 4-5 on the laptop",
      ("VA2446", B, B), tuple(place(["VA2446", B])[w] for w in "145"))
check("laptop closed: 1 left, 2-3 right", (L, R, R), tuple(place([L, R])[w] for w in "123"))
sys.exit(1 if bad else 0)
PY

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
