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
  if [[ "\$1" == -e ]]; then echo "\$2" >> "$T/script.log"; shift 2
  else echo "\$1" >> "$T/argv.log"; shift; fi
done
exit 0
EOF
  # pgrep: Hammerspoon is running, nothing else is.
  printf '#!/bin/bash\necho "pgrep $*" >> "%s"\n[[ "$*" == *Hammerspoon* ]]\n' "$LOG" > "$STUBS/pgrep"
  chmod +x "$STUBS"/*
}

# run <theme name>: no tty on stdout, stub PATH first, /bin/bash via env.
run() {
  OUT="$T/out.txt"
  env -i HOME="$H" USER="$USER" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
      XDG_CONFIG_HOME="$H/.config" CLAUDE_CONFIG_DIR="$H/.claude" \
      /bin/bash "$THEME_BIN" "$1" > "$OUT" 2>&1 < /dev/null
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

echo "theme --sync takes the commit pinned in OMARCHY_COMMIT (#45):"
setup
UP="$T/upstream"; mkdir -p "$UP/default/themed" "$UP/themes/pinned" "$UP/themes/bad;name"
for t in btop.theme.tpl ghostty.conf.tpl neovim.lua.tpl claude.json.tpl obsidian.css.tpl; do
  echo "# {{ background }}" > "$UP/default/themed/$t"
done
cp "$FIXTURE/colors.toml" "$UP/themes/pinned/colors.toml"
cp "$FIXTURE/colors.toml" "$UP/themes/bad;name/colors.toml"
mkdir -p "$UP/themes/pinned/backgrounds"
echo ok > "$UP/themes/pinned/backgrounds/1-ok.jpg"
echo bad > "$UP/themes/pinned/backgrounds/bad 'name' & \$(id).jpg"
mkdir -p "$UP/themes/pinned/backgrounds/intros"
echo video > "$UP/themes/pinned/backgrounds/intros/1-ok.mp4"
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
check "syncs the theme intro (Omarchy 4.5)" test -f "$H/Pictures/Wallpapers/intros/pinned_1-ok.mp4"
check "an intro is not a wallpaper of its own" test ! -e "$H/Pictures/Wallpapers/pinned_1-ok.mp4"
[[ "$CODE" -eq 0 ]] || cat "$T/sync.txt"
rm "$T/repo/OMARCHY_COMMIT"
env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" TMPDIR="$T" \
    /bin/bash "$H/.local/bin/theme" --sync > "$T/sync.txt" 2>&1 < /dev/null
check "no OMARCHY_COMMIT: sync refuses" test "$?" -ne 0
rm -rf "$T"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
