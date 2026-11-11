#!/bin/bash
# Checks the Omarchy 4.5 window fixes (#39) with fake `aerospace`, `ps`,
# `lsof`, `open` and `hs` on PATH, so nothing on the Mac moves:
#   - ⌥↩ (bin/omarchy-terminal) opens Ghostty in the focused terminal's folder,
#     and in $HOME for any other app (omacom/omarchy#15007);
#   - ⌘⌃⇧arrow (bin/omarchy-move-to-monitor) centres a floating window on the
#     monitor it lands on (omacom/omarchy#14549);
#   - 1Password and Bitwarden float (omacom/omarchy#11704), and the float
#     rules are listed in aerospace.toml;
#   - ⌘⌥⇧` cycles back through every window, floating ones too
#     (omacom/omarchy#8576).
#
#   tests/window-fixes-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin"
TOML="${AEROSPACE_TOML:-$HERE/../aerospace/aerospace.toml}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

mkdir -p "$TMP/bin" "$TMP/home" "$TMP/project dir"
# Each fake logs its arguments and answers from a file the test writes.
cat >"$TMP/bin/aerospace" <<'SH'
#!/bin/bash
echo "aerospace $*" >>"$FAKE/log"
case "$*" in
  "list-windows --focused --format %{app-pid}") cat "$FAKE/app-pid" ;;
  "list-windows --focused --format "*) cat "$FAKE/focused" ;;
  move-node-to-monitor*) exit "$(cat "$FAKE/move-exit")" ;;
esac
SH
cat >"$TMP/bin/ps" <<'SH'
#!/bin/bash
cat "$FAKE/ps"
SH
cat >"$TMP/bin/lsof" <<'SH'
#!/bin/bash
# lsof -a -p <pid> -d cwd -Fn
pid=$3
echo "p$pid"; echo fcwd; grep "^$pid " "$FAKE/cwds" | cut -d' ' -f2- | sed 's/^/n/'
SH
for f in open hs; do
  printf '#!/bin/bash\necho "%s $*" >>"$FAKE/log"\n' "$f" >"$TMP/bin/$f"
done
chmod +x "$TMP/bin/"*
export FAKE="$TMP" PATH="$TMP/bin:$PATH" HOME="$TMP/home" AEROSPACE="$TMP/bin/aerospace" HS="$TMP/bin/hs"
echo "500 $TMP/project dir" >"$TMP/cwds"
echo "700 $TMP/Downloads" >>"$TMP/cwds"
echo "810 $TMP/project dir" >>"$TMP/cwds"
mkdir -p "$TMP/Downloads"

terminal() { # terminal -> the folder the new Ghostty window opens in
  : >"$TMP/log"
  "$BIN/omarchy-terminal"
  sed -n 's/^open -na Ghostty --args --working-directory=//p' "$TMP/log"
}

echo "omarchy-terminal:"
# Ghostty on macOS: ghostty starts login on a new pty (a session leader),
# and login starts the shell.
cat >"$TMP/ps" <<'PS'
  100     1 S    ??       /Applications/Ghostty.app/Contents/MacOS/ghostty
  499   100 Ss+  ttys001  /usr/bin/login
  500   499 S+   ttys001  -zsh
  510   500 S+   ttys001  nvim
PS
echo 100 >"$TMP/app-pid"
check "a terminal's shell gives its folder" "$TMP/project dir" "$(terminal)"

# A browser keeps a helper shell in Downloads, with no pty of its own.
cat >"$TMP/ps" <<'PS'
  200     1 S    ??       /Applications/Brave.app/Contents/MacOS/Brave
  700   200 S    ??       /bin/bash
PS
echo 200 >"$TMP/app-pid"
check "a browser's helper shell gives HOME" "$TMP/home" "$(terminal)"

# The same browser started from a terminal: its helper shares that terminal's
# pty, but neither leads a session of its own.
cat >"$TMP/ps" <<'PS'
  200   500 S+   ttys001  /Applications/Brave.app/Contents/MacOS/Brave
  700   200 S+   ttys001  /bin/bash
PS
check "a browser started from a terminal gives HOME" "$TMP/home" "$(terminal)"

# A terminal that runs the shell itself as the session leader (Linux style).
cat >"$TMP/ps" <<'PS'
  800     1 S    ??       /Applications/Alacritty.app/Contents/MacOS/alacritty
  810   800 Ss+  ttys004  /bin/zsh
PS
echo 800 >"$TMP/app-pid"
check "a shell that leads its own session gives its folder" "$TMP/project dir" "$(terminal)"

: >"$TMP/app-pid"
check "no focused window gives HOME" "$TMP/home" "$(terminal)"

echo "omarchy-move-to-monitor:"
move() { : >"$TMP/log"; "$BIN/omarchy-move-to-monitor" "$@"; grep -v ' list-windows ' "$TMP/log" | tr '\n' ';'; }
echo 0 >"$TMP/move-exit"
echo "42 floating 2" >"$TMP/focused"
check "a floating window moves, then centres on its new monitor" \
  'aerospace move-node-to-monitor --wrap-around --focus-follows-window right;hs -c local w, s = hs.window.get(42), hs.screen.allScreens()[2]; if w and s then w:centerOnScreen(s, true, 0) end;' "$(move right)"
echo "42 h_tiles 2" >"$TMP/focused"
check "a tiled window only moves (AeroSpace tiles it)" \
  'aerospace move-node-to-monitor --wrap-around --focus-follows-window left;' "$(move left)"
echo 1 >"$TMP/move-exit"
echo "42 floating 1" >"$TMP/focused"
check "no other monitor: nothing is centred" \
  'aerospace move-node-to-monitor --wrap-around --focus-follows-window up;' "$(move up)"

key() { # key <aerospace key> -> its main-mode command
  python3 - "$TOML" "$1" <<'PY'
import sys, tomllib
print(tomllib.load(open(sys.argv[1], "rb"))["mode"]["main"]["binding"].get(sys.argv[2], ""))
PY
}

echo "aerospace.toml:"
check "⌥↩ opens a terminal in the focused folder" \
  'exec-and-forget $HOME/.local/bin/omarchy-terminal' "$(key alt-enter)"
for dir in left right up down; do
  check "⌘⌃⇧$dir moves the window and centres a float" \
    "exec-and-forget \$HOME/.local/bin/omarchy-move-to-monitor $dir" "$(key cmd-ctrl-shift-$dir)"
done
# AeroSpace's dfs order puts floating windows in the tree (unless
# --ignore-floating), so the backward cycle reaches every window: no
# z-order to ping-pong on, as Hyprland's had.
check "⌘⌥⇧\` cycles back through every window, floating ones too" \
  'focus --boundaries-action wrap-around-the-workspace dfs-prev' "$(key cmd-alt-shift-backtick)"
check "⌘⌥\` cycles forward the same way" \
  'focus --boundaries-action wrap-around-the-workspace dfs-next' "$(key cmd-alt-backtick)"

floats=$(python3 - "$TOML" <<'PY'
import sys, tomllib
for r in tomllib.load(open(sys.argv[1], "rb")).get("on-window-detected", []):
    run = r["run"] if isinstance(r["run"], list) else [r["run"]]
    if "layout floating" in run and "app-id" in r.get("if", {}):
        print(r["if"]["app-id"])
PY
)
for id in com.1password.1password com.agilebits.onepassword7 com.bitwarden.desktop; do
  check "$id floats" 1 "$(grep -cx "$id" <<<"$floats")"
done
# The list at the head of the rules names every app-id that floats.
listed=$(sed -n '/^# Float rules:/,/^$/p' "$TOML")
missing=""
for id in $floats; do grep -qF "$id" <<<"$listed" || missing="$missing $id"; done
check "every float rule is in the list" "" "$missing"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
