#!/bin/bash
# End-to-end tests for bin/theme, run the way a hotkey runs it: no terminal,
# macOS system bash (3.2), in a throwaway HOME. Every tool that would touch
# the real desktop (osascript, hs, sketchybar, nvim, pkill, pgrep) is a stub
# that logs its arguments, so nothing on this Mac changes.
#
#   tests/theme-test.sh                 test bin/theme next to this file
#   THEME_BIN=/path/to/theme tests/theme-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
THEME_BIN="${THEME_BIN:-$HERE/../bin/theme}"
FIXTURE="$HERE/fixtures/theme-cache/jade"
fails=0

setup() {
  T="$(mktemp -d)"
  H="$T/home"; STUBS="$T/stubs"; LOG="$T/calls.log"
  mkdir -p "$H/.config/theme-switcher/cache" "$H/Pictures/Wallpapers" \
           "$H/.config/ghostty/themes" "$H/.claude" "$H/.config/sketchybar" "$STUBS"
  # Two themes with the same colors: "withwall" has a wallpaper, "nowall" has none.
  cp -R "$FIXTURE" "$H/.config/theme-switcher/cache/withwall"
  cp -R "$FIXTURE" "$H/.config/theme-switcher/cache/nowall"
  : > "$H/Pictures/Wallpapers/withwall_1.jpg"
  printf 'theme = omarchy-withwall\n' > "$H/.config/ghostty/config"
  : > "$LOG"
  for cmd in osascript hs sketchybar nvim pkill; do
    printf '#!/bin/bash\necho "%s $*" >> "%s"\nexit 0\n' "$cmd" "$LOG" > "$STUBS/$cmd"
  done
  # osascript also logs its script text (-e) and its argv apart (#50).
  cat > "$STUBS/osascript" <<EOF
#!/bin/bash
echo "osascript \$*" >> "$LOG"
while [[ \$# -gt 0 ]]; do
  if [[ "\$1" == -e ]]; then echo "\$2" >> "$T/script.log"
    # the desktop picture a test put in \$T/desktop
    [[ "\$2" == *"get picture"* ]] && cat "$T/desktop" 2>/dev/null
    shift 2
  else echo "\$1" >> "$T/argv.log"; shift; fi
done
exit 0
EOF
  # pgrep: Hammerspoon is running, nothing else is.
  printf '#!/bin/bash\necho "pgrep $*" >> "%s"\n[[ "$*" == *Hammerspoon* ]]\n' "$LOG" > "$STUBS/pgrep"
  chmod +x "$STUBS"/*
}

# run <theme args...>: no tty on stdout, stub PATH first, /bin/bash via env.
run() {
  OUT="$T/out.txt"
  env -i HOME="$H" USER="$USER" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
      XDG_CONFIG_HOME="$H/.config" CLAUDE_CONFIG_DIR="$H/.claude" ${SYNC_FROM:+THEME_SYNC_FROM="$SYNC_FROM"} \
      /bin/bash "$THEME_BIN" "$@" > "$OUT" 2>&1 < /dev/null
  CODE=$?
  sleep 0.3   # the alert is sent in the background
  LC_ALL=C sed $'s/\033\\[[0-9;]*m//g' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
}

check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

echo "theme with no wallpaper (bash 3.2, hotkey):"
setup; run nowall
check "exits 0" test "$CODE" -eq 0
check "runs to the end (prints done.)" grep -q '^done\.' "$OUT"
check "writes the state file" grep -qx nowall "$H/.config/theme-switcher/current"
check "points Ghostty at the theme" grep -qx 'theme = omarchy-nowall' "$H/.config/ghostty/config"
check "does not set a desktop picture" bash -c "! grep -q 'set picture' '$LOG'"
check "shows one alert with the wallpaper message" \
  grep -qF 'hs -c hs.alert.show([[Switched to nowall. No wallpaper for this theme in ~/Pictures/Wallpapers, so the previous wallpaper stays.]], 5)' "$LOG"
rm -rf "$T"

echo "theme with a wallpaper (bash 3.2, hotkey):"
setup; run withwall
check "exits 0" test "$CODE" -eq 0
check "runs to the end (prints done.)" grep -q '^done\.' "$OUT"
check "writes the state file" grep -qx withwall "$H/.config/theme-switcher/current"
check "sets the wallpaper" grep -q 'set picture of every desktop to item 1 of argv' "$T/script.log"
check "passes the wallpaper path as an argument" grep -qx "$H/Pictures/Wallpapers/withwall_1.jpg" "$T/argv.log"
check "shows no alert" bash -c "! grep -q 'hs.alert' '$LOG'"
check "sends no macOS notification" bash -c "! grep -q 'display notification' '$LOG'"
rm -rf "$T"

echo "terminal output:"
setup; run withwall
check "Ghostty line says open windows reload through Hammerspoon" \
  grep -q 'ghostty  open windows reload through Hammerspoon' "$OUT"
check "no 'new windows only' line" bash -c "! grep -q 'new windows only' '$OUT'"
rm -rf "$T"

echo "theme name with shell, Lua or AppleScript metacharacters (#45):"
for bad in 'bad]]os.exit()--' 'bad"name' 'bad;id' 'bad$(id)'; do
  setup; mkdir -p "$H/.config/theme-switcher/cache/$bad"; run "$bad"
  check "refuses '$bad'" test "$CODE" -ne 0
  check "'$bad': says the name is invalid" grep -q 'invalid theme name' "$OUT"
  check "'$bad': no alert or notification" bash -c "! grep -qE 'hs -c|osascript' '$LOG'"
  check "'$bad': state file untouched" bash -c "! grep -q bad '$H/.config/theme-switcher/current' 2>/dev/null"
  rm -rf "$T"
done

echo "wallpaper file name with a quote reaches osascript as an argument (#50):"
setup; rm "$H/Pictures/Wallpapers/withwall_1.jpg"
BADWALL="$H/Pictures/Wallpapers/withwall_x\" & (do shell script \"id\") & \".jpg"
: > "$BADWALL"; run withwall
check "exits 0" test "$CODE" -eq 0
check "no wallpaper path in the script text" bash -c "[[ -s '$T/script.log' ]] && ! grep -q Wallpapers '$T/script.log'"
check "passes the path as an argument" grep -qxF "$BADWALL" "$T/argv.log"
rm -rf "$T"

echo "each theme reopens with its last wallpaper (omacom/omarchy#7718):"
setup; rm "$H/Pictures/Wallpapers/withwall_1.jpg"
for i in 1 2 3 4 5; do : > "$H/Pictures/Wallpapers/withwall_$i.jpg"; done
echo withwall > "$H/.config/theme-switcher/current"
echo "$H/Pictures/Wallpapers/withwall_4.jpg" > "$T/desktop"
run nowall
check "remembers the outgoing theme's wallpaper" \
  grep -qx "$H/Pictures/Wallpapers/withwall_4.jpg" "$H/.config/theme-switcher/backgrounds/withwall"
echo /Library/Desktop\ Pictures/Sonoma.heic > "$T/desktop"
for i in 1 2 3; do
  : > "$T/argv.log"; run withwall
  check "switch back $i sets the remembered wallpaper" grep -qx "$H/Pictures/Wallpapers/withwall_4.jpg" "$T/argv.log"
  echo nowall > "$H/.config/theme-switcher/current"
done
check "the cycler starts from the remembered wallpaper" grep -qx 3 "$H/.cache/omarchy-wallpaper-index-withwall"
check "an outside picture is remembered too" grep -qx "/Library/Desktop Pictures/Sonoma.heic" "$H/.config/theme-switcher/backgrounds/nowall"
rm "$H/Pictures/Wallpapers/withwall_4.jpg"; : > "$T/argv.log"; run withwall
check "a deleted remembered wallpaper falls back to another of the theme" \
  grep -qE "^$H/Pictures/Wallpapers/withwall_[1235]\.jpg$" "$T/argv.log"
echo "$H/Pictures/Wallpapers/withwall_4.jpg" > "$T/desktop"
echo nowall > "$H/.config/theme-switcher/current"; run withwall
check "a picture left from another theme is not remembered for the outgoing one" \
  bash -c "! grep -q withwall_4 '$H/.config/theme-switcher/backgrounds/nowall'"
rm -rf "$T"

echo "theme --remove deletes a theme (omacom/omarchy#14713):"
setup; echo withwall > "$H/.config/theme-switcher/current"
: > "$H/.config/ghostty/themes/omarchy-nowall"
mkdir -p "$H/.config/btop/themes"; : > "$H/.config/btop/themes/omarchy-nowall.theme"
run --remove nowall
check "exits 0" test "$CODE" -eq 0
check "deletes the cached theme" test ! -e "$H/.config/theme-switcher/cache/nowall"
check "deletes its Ghostty theme" test ! -e "$H/.config/ghostty/themes/omarchy-nowall"
check "deletes its btop theme" test ! -e "$H/.config/btop/themes/omarchy-nowall.theme"
check "remembers it so --sync skips it" grep -qx nowall "$H/.config/theme-switcher/removed"
run --remove withwall
check "refuses the current theme" test "$CODE" -ne 0
check "keeps the current theme" test -d "$H/.config/theme-switcher/cache/withwall"
run --remove 'bad;id'
check "refuses an invalid name" test "$CODE" -ne 0
run --remove nosuch
check "refuses an unknown theme" test "$CODE" -ne 0
rm -rf "$T"

echo "herdr theme sync (omacom/omarchy#13430):"
herdr_setup() {
  setup
  printf '#!/bin/bash\n[[ "$*" == "machine list" ]] && printf "1\\tbox\\tme@box\\tmain\\tenabled\\n2\\toff\\tme@off\\tmain\\tdisabled\\n"\nexit 0\n' > "$STUBS/herdr"
  # ssh runs the remote script here, in a second HOME: a Mac running omarchy4mac
  R="$T/remote"; mkdir -p "$R/.local/bin" "$R/.config/theme-switcher"
  printf '#!/bin/bash\necho "remote-theme $* from=$THEME_SYNC_FROM" >> "%s"\n' "$T/remote.log" > "$R/.local/bin/theme"
  cat > "$STUBS/ssh" <<EOF
#!/bin/bash
echo "ssh \$*" >> "$LOG"
HOME="$R" /bin/bash -s
EOF
  chmod +x "$STUBS"/* "$R/.local/bin/theme"
}
wait_for() { local i; for i in 1 2 3 4 5 6 7 8 9 10; do [[ -s "$1" ]] && grep -q "$2" "$1" && return 0; sleep 0.3; done; return 1; }
herdr_setup; touch "$R/.config/theme-switcher/herdr-sync"
run --herdr-sync on
check "the toggle turns on" test -f "$H/.config/theme-switcher/herdr-sync"
run withwall
check "the switch still exits 0" test "$CODE" -eq 0
wait_for "$H/.local/state/omarchy4mac/theme-herdr.log" "me@box"
check "pushes to the enabled machine" grep -q 'ssh .*me@box' "$LOG"
check "skips the disabled machine" bash -c "! grep -q 'me@off' '$LOG'"
check "the remote switches with THEME_SYNC_FROM set" grep -qE '^remote-theme withwall from=.+' "$T/remote.log"
check "logs one result line" grep -q 'me@box: set withwall' "$H/.local/state/omarchy4mac/theme-herdr.log"
rm -f "$R/.config/theme-switcher/herdr-sync"; run nowall
wait_for "$H/.local/state/omarchy4mac/theme-herdr.log" "sync is off"
check "a remote with sync off stays put" bash -c "! grep -q 'remote-theme nowall' '$T/remote.log'"
check "logs that the remote's sync is off" grep -q 'me@box: theme sync is off' "$H/.local/state/omarchy4mac/theme-herdr.log"
: > "$LOG"; SYNC_FROM=otherhost run withwall; sleep 1
check "a theme from another machine is not echoed back" bash -c "! grep -q '^ssh' '$LOG'"
run --herdr-sync off
check "the toggle turns off" test ! -e "$H/.config/theme-switcher/herdr-sync"
: > "$LOG"; run nowall; sleep 1
check "sync off: no push" bash -c "! grep -q '^ssh' '$LOG'"
rm -rf "$T"
# One machine asleep: ssh exits 255 there, and the next machine still gets the theme
herdr_setup; touch "$R/.config/theme-switcher/herdr-sync"
printf '#!/bin/bash\n[[ "$*" == "machine list" ]] && printf "1\\tdown\\tme@down\\tmain\\tenabled\\n2\\tbox\\tme@box\\tmain\\tenabled\\n"\nexit 0\n' > "$STUBS/herdr"
cat > "$STUBS/ssh" <<EOF
#!/bin/bash
echo "ssh \$*" >> "$LOG"
[[ "\$*" == *me@down* ]] && { cat >/dev/null; echo "ssh: connect to host down: Operation timed out" >&2; exit 255; }
HOME="$R" /bin/bash -s
EOF
chmod +x "$STUBS"/*
run --herdr-sync on; run withwall
wait_for "$H/.local/state/omarchy4mac/theme-herdr.log" "me@box"
check "an unreachable machine is logged" grep -q 'me@down: unreachable' "$H/.local/state/omarchy4mac/theme-herdr.log"
check "the next machine still gets the theme" grep -q 'me@box: set withwall' "$H/.local/state/omarchy4mac/theme-herdr.log"
rm -rf "$T"

echo "theme --sync takes the commit pinned in OMARCHY_COMMIT (#45):"
setup
UP="$T/upstream"; mkdir -p "$UP/default/themed" "$UP/themes/pinned" "$UP/themes/bad;name"
for t in btop.theme.tpl ghostty.conf.tpl neovim.lua.tpl claude.json.tpl obsidian.css.tpl; do
  echo "# {{ background }}" > "$UP/default/themed/$t"
done
cp "$FIXTURE/colors.toml" "$UP/themes/pinned/colors.toml"
cp "$FIXTURE/colors.toml" "$UP/themes/bad;name/colors.toml"
mkdir -p "$UP/themes/catppuccin" "$UP/themes/gone"
cp "$FIXTURE/colors.toml" "$UP/themes/catppuccin/colors.toml"
cp "$FIXTURE/colors.toml" "$UP/themes/gone/colors.toml"
printf 'return {\n  { "catppuccin/nvim", name = "catppuccin" },\n  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-nvim" } },\n}\n' > "$UP/themes/catppuccin/neovim.lua"
echo gone > "$H/.config/theme-switcher/removed"
mkdir -p "$UP/themes/pinned/backgrounds"
echo ok > "$UP/themes/pinned/backgrounds/1-ok.jpg"
echo bad > "$UP/themes/pinned/backgrounds/bad 'name' & \$(id).jpg"
g() { git -C "$UP" -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@" >/dev/null 2>&1; }
g init -q -b quattro; g add -A; g commit -qm pinned
PIN="$(git -C "$UP" rev-parse HEAD)"
mkdir -p "$UP/themes/later"; cp "$FIXTURE/colors.toml" "$UP/themes/later/colors.toml"
g add -A; g commit -qm later
g config uploadpack.allowFilter true; g config uploadpack.allowAnySHA1InWant true
# the installed layout: ~/.local/bin/theme is a symlink into the repo clone
mkdir -p "$T/repo/bin" "$H/.local/bin"
cp "$THEME_BIN" "$T/repo/bin/theme"; echo "$PIN" > "$T/repo/OMARCHY_COMMIT"
ln -s "$T/repo/bin/theme" "$H/.local/bin/theme"
env -i HOME="$H" USER="$USER" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
    XDG_CONFIG_HOME="$H/.config" CLAUDE_CONFIG_DIR="$H/.claude" \
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$UP.insteadOf" \
    GIT_CONFIG_VALUE_0="https://github.com/omacom/omarchy.git" \
    /bin/bash "$H/.local/bin/theme" --sync > "$T/sync.txt" 2>&1 < /dev/null
CODE=$?
check "sync exits 0" test "$CODE" -eq 0
check "syncs the theme at the pinned commit" test -f "$H/.config/theme-switcher/cache/pinned/colors.toml"
check "does not take the branch head" test ! -e "$H/.config/theme-switcher/cache/later"
check "skips an upstream theme with an invalid name" test ! -e "$H/.config/theme-switcher/cache/bad;name"
check "syncs a background with a valid name" test -f "$H/Pictures/Wallpapers/pinned_1-ok.jpg"
check "skips a background with an invalid name (#50)" bash -c "! ls '$H/Pictures/Wallpapers' | grep -q bad"
check "does not bring back a removed theme" test ! -e "$H/.config/theme-switcher/cache/gone"
check "Catppuccin: Neovim gets catppuccin-mocha (omacom/omarchy#12864)" \
  grep -q '"catppuccin-mocha"' "$H/.config/theme-switcher/cache/catppuccin/neovim.lua"
check "Catppuccin: no catppuccin-nvim left" bash -c "! grep -q catppuccin-nvim '$H/.config/theme-switcher/cache/catppuccin/neovim.lua'"
[[ "$CODE" -eq 0 ]] || cat "$T/sync.txt"
rm "$T/repo/OMARCHY_COMMIT"
env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
    /bin/bash "$H/.local/bin/theme" --sync > "$T/sync.txt" 2>&1 < /dev/null
check "no OMARCHY_COMMIT: sync refuses" test "$?" -ne 0
rm -rf "$T"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
