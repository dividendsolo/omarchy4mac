#!/bin/bash
# Checks README.md's tables against the config they describe, so they cannot
# drift again (the four chord rows and the alias table had, #13): every chord
# a keybinding row prints must be bound in aerospace/aerospace.toml or
# hammerspoon/init.lua, and the shell alias table must be exactly the aliases
# and functions zsh/omarchy.zsh sets.
# One direction only: the README may group bindings (⌥1–5), so this checks
# what it prints, not that the config has nothing unprinted.
#
#   tests/readme-test.sh
#   README=/path/to/README.md tests/readme-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
README="${README:-$HERE/../README.md}"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
ZSH="${ZSH_FILE:-$HERE/../zsh/omarchy.zsh}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

read -r -d '' PY <<'PYEOF'
import re, sys, pathlib, tomllib

readme, toml_text, lua_text, zsh_text = (pathlib.Path(p).read_text() for p in sys.argv[1:5])

# ---- what the config binds ------------------------------------------------
MODS = {"cmd": 0, "ctrl": 1, "alt": 2, "shift": 3}
KEYS = {"enter": "enter", "tab": "tab", "backspace": "backspace", "space": "space",
        "esc": "esc", "backtick": "backtick", "slash": "slash", "comma": "comma",
        "period": "period", "equal": "equal", "minus": "minus", "semicolon": "semicolon"}

def canon(parts):
    """<mods...> <key> (in any order) -> one canonical chord name."""
    mods = sorted((p for p in parts if p in MODS), key=lambda p: MODS[p])
    keys = [p for p in parts if p not in MODS]
    return "-".join(mods + keys) if len(keys) == 1 else ""

bound = set()
cfg = tomllib.loads(toml_text)
for mode in cfg.get("mode", {}).values():
    for key in mode.get("binding", {}):
        bound.add(canon(key.split("-")))
# hs.hotkey.bind({"cmd","ctrl","shift"}, "space", …) — the display list above is
# not a binding, so only the calls count.
for mods, key in re.findall(r'hs\.hotkey\.bind\(\s*\{([^}]*)\}\s*,\s*"([^"]+)"', lua_text):
    bound.add(canon([m.strip().strip('"') for m in mods.split(",")] + [key]))
print(f"# {len(bound)} chords bound in the config")

# ---- README notation ------------------------------------------------------
GLYPH_MOD = {"⌘": "cmd", "⌃": "ctrl", "⌥": "alt", "⇧": "shift"}
GLYPH_KEY = {"↩": "enter", "⇥": "tab", "⌫": "backspace", "⎵": "space", "⎋": "esc",
             "`": "backtick", "/": "slash", ",": "comma", ".": "period",
             "=": "equal", "-": "minus", ";": "semicolon"}

def readme_chord(cell):
    """One README key cell -> canonical chord, or '' when it is not one chord."""
    mods, key = [], ""
    for ch in cell:
        if ch in GLYPH_MOD:
            mods.append(GLYPH_MOD[ch])
        elif ch in GLYPH_KEY:
            key = GLYPH_KEY[ch]
        elif ch.isalnum():
            key = ch.lower()
        else:
            return ""
    return canon(mods + [key]) if key else ""

def rows(table_start, table_end):
    for keys, rest in re.findall(r"^\|\s*(.+?)\s*\|\s*(.+?)\s*\|$",
                                 readme[table_start:table_end], re.M):
        if keys not in ("Keys", "---", "Alias"):
            yield keys, rest

# ---- keybinding rows ------------------------------------------------------
start = readme.index("## Keybindings")
end = readme.index("### Shell Aliases")   # the alias table is checked below
missing = []
for cell, action in rows(start, end):
    cell = cell.strip()
    chords = [readme_chord(cell)]
    if chords == [""]:
        # A row may print several chords (⌘⌃T / ⌥⇧T); check each. Ranges such
        # as ⌥1–5 and ⌘⇧←/↓/↑/→ are not single chords and are skipped.
        chords = [c for part in cell.split("/")
                  for c in (readme_chord(part.strip()),) if c]
    for chord in chords:
        if chord and chord not in bound:
            missing.append(f"{cell} -> {chord} ({action})")
print("; ".join(missing))

# ---- shell aliases --------------------------------------------------------
start = readme.index("### Shell Aliases")
end = readme.index("\n## ", start)
table = {name for cell, _ in rows(start, end)
          for name in (t.strip("`").split()[0] for t in re.findall(r"`[^`]+`", cell)) if name}

aliases = set(re.findall(r"^\s*alias\s+([^\s=]+)=", zsh_text, re.M))
functions = {f for f in re.findall(r"^([A-Za-z_][\w.-]*)\(\)\s*\{", zsh_text, re.M)
             if not f.startswith("_")}   # private helpers are not for the table
# The table lists what a user can type: an alias or one of the layout functions.
print("; ".join(sorted(table - aliases - functions)))   # printed but not set
print("; ".join(sorted(aliases - table)))               # set but not printed
PYEOF

OUT="$(python3 -c "$PY" "$README" "$TOML" "$LUA" "$ZSH")" ||
  { echo "FAIL: could not parse README.md or the config"; exit 1; }
BOUND="$(printf '%s\n' "$OUT" | sed -n 1p)"
UNKNOWN="$(printf '%s\n' "$OUT" | sed -n 2p)"
DOC_MISSING="$(printf '%s\n' "$OUT" | sed -n 3p)"
SCRIPT_MISSING="$(printf '%s\n' "$OUT" | sed -n 4p)"

echo "config: $BOUND"
echo "README.md keybindings vs the config:"
check "every chord a row prints is bound" "" "$UNKNOWN"
echo "README.md shell alias table vs zsh/omarchy.zsh:"
check "every alias the table prints is set" "" "$DOC_MISSING"
check "every alias omarchy.zsh sets is printed" "" "$SCRIPT_MISSING"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
