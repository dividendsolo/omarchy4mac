#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOML="$HERE/../aerospace/aerospace.toml"
fails=0

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
    check(f"alt-{n} goes to workspace {n}, on whatever monitor holds it", f"workspace {n}", b[f"alt-{n}"])
    check(f"cmd-shift-{n} moves the window to workspace {n} and follows it", [f"move-node-to-workspace {n}", f"workspace {n}"], b[f"cmd-shift-{n}"])
    check(f"cmd-shift-alt-{n} moves the window to workspace {n} and stays", f"move-node-to-workspace {n}", b[f"cmd-shift-alt-{n}"])
for k in ("left", "down", "up", "right"):
    check(f"cmd-{k} crosses to the neighbouring display", f"focus --boundaries all-monitors-outer-frame {k}", b[f"cmd-{k}"])
check("alt-tab cycles the focused monitor's workspaces", "workspace --wrap-around next", b["alt-tab"])
check("cmd-ctrl-tab keeps back-and-forth", "workspace-back-and-forth", b["cmd-ctrl-tab"])

def place(monitors):
    out = {}
    for ws, pats in assign.items():
        pats = [pats] if isinstance(pats, str) else pats
        out[ws] = next((m for p in pats for m in monitors if re.search(p, m, re.I)), None)
    return out
L, R, B = "VA2446 (1)", "VA2446 (2)", "Built-in Retina Display"
full = place([L, R, B])
check("all plugged in: 1 left, 2-3 right, 4-5 laptop", {"1": L, "2": R, "3": R, "4": B, "5": B}, full)
check("left unplugged: 2-3 stay on the right, 4-5 on the laptop",
      ("VA2446", "VA2446", B, B), tuple(place(["VA2446", B])[w] for w in "2345"))
check("right unplugged: 1 stays on the left, 4-5 on the laptop",
      ("VA2446", B, B), tuple(place(["VA2446", B])[w] for w in "145"))
check("laptop closed: 1 left, 2-3 right", (L, R, R), tuple(place([L, R])[w] for w in "123"))
sys.exit(1 if bad else 0)
PY

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
