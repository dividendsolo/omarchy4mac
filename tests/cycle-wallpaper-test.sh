#!/bin/bash
# Tests for bin/omarchy-cycle-wallpaper in a throwaway HOME. osascript is a
# stub that logs its script text (-e) and its argv apart, so nothing changes.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin/omarchy-cycle-wallpaper"
fails=0
check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

T="$(mktemp -d)"; H="$T/home"; STUBS="$T/stubs"
mkdir -p "$H/Pictures/Wallpapers" "$H/.config/theme-switcher" "$STUBS"
echo jade > "$H/.config/theme-switcher/current"
cat > "$STUBS/osascript" <<EOF
#!/bin/bash
while [[ \$# -gt 0 ]]; do
  if [[ "\$1" == -e ]]; then echo "\$2" >> "$T/script.log"; shift 2
  else echo "\$1" >> "$T/argv.log"; shift; fi
done
EOF
chmod +x "$STUBS/osascript"

echo "wallpaper file name with a quote reaches osascript as an argument (#50):"
BAD="$H/Pictures/Wallpapers/jade_x\" & (do shell script \"id\") & \".jpg"
: > "$BAD"
OUT="$(env -i HOME="$H" PATH="$STUBS:/usr/bin:/bin" /bin/bash "$BIN" 2>&1)"
check "exits 0" test "$?" -eq 0
check "prints the picture name" bash -c '[[ "$1" == "Wallpaper|||jade_x"* ]]' _ "$OUT"
check "script sets the picture from argv" grep -q 'set picture of every desktop to item 1 of argv' "$T/script.log"
check "no wallpaper path in the script text" bash -c "[[ -s '$T/script.log' ]] && ! grep -q Wallpapers '$T/script.log'"
check "passes the path as an argument" grep -qxF "$BAD" "$T/argv.log"
rm -rf "$T"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
