#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

WAIT="$(sed -n '/^wait_app() {/,/^}/p' "$ROOT/install.sh")"
[[ -n "$WAIT" ]] || { echo "FAIL: install.sh has no wait_app helper"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STUBS="$TMP/bin"; LOG="$TMP/calls"
mkdir -p "$STUBS"

stub() {
  printf '#!/bin/bash\n%s\n' "$2" > "$STUBS/$1"
  chmod +x "$STUBS/$1"
}

stub sleep "echo \"sleep \$*\" >> \"$LOG\""
stub pgrep "echo \"pgrep \$*\" >> \"$LOG\"
grep -qx -- \"\${@: -1}\" \"$TMP/running\""
stub hs "echo \"hs \$*\" >> \"$LOG\"
n=\"\$(cat \"$TMP/tries\" 2>/dev/null || echo 0)\"
n=\$((n + 1))
echo \"\$n\" > \"$TMP/tries\"
[ \"\$n\" -ge 3 ] && { echo 1; exit 0; }
exit 1"

waits() {
  printf '%s\nwait_app hs hs -t 2 -c "return 1"\n' "$WAIT" > "$TMP/wait.sh"
  PATH="$STUBS:/usr/bin:/bin" HOME="$TMP" /bin/bash "$TMP/wait.sh" >/dev/null 2>&1
  echo $?
}

setup_one() {
  : > "$LOG"
  rm -f "$TMP/tries"
  : > "$TMP/running"
}

sleeps() { grep -c '^sleep' "$LOG"; }
called_hs() { grep -c '^hs ' "$LOG"; }

echo "an app that answers on the third try:"
setup_one
printf 'hs\n' > "$TMP/running"
check "the wait returns 0" 0 "$(waits)"
check "the command is retried" 3 "$(called_hs)"
check "it slept between the tries" 2 "$(sleeps)"

echo "an app that never answers:"
setup_one
check "the wait gives up with 1" 1 "$(waits)"
check "it is bounded" 30 "$(sleeps)"

echo "an app that is not running (the hs command hangs on its own once Hammerspoon is gone):"
setup_one
: > "$TMP/running"
check "the wait gives up with 1" 1 "$(waits)"
check "the command is never called" 0 "$(called_hs)"

echo "the install wiring:"
line_of() { grep -n "$1" "$ROOT/install.sh" | head -n1 | cut -d: -f1; }
check "the install ends AeroSpace with a signal" 1 "$(grep -c 'stop_app AeroSpace' "$ROOT/install.sh")"
check "the install ends Hammerspoon with a signal" 1 "$(grep -c 'stop_app Hammerspoon' "$ROOT/install.sh")"
check "the install waits for AeroSpace" 1 "$(grep -c 'wait_app AeroSpace' "$ROOT/install.sh")"
check "the install waits for Hammerspoon" 1 "$(grep -c 'wait_app Hammerspoon' "$ROOT/install.sh")"
check "the wait runs before the Done line" "yes" \
  "$( [ "$(line_of 'wait_app AeroSpace')" -lt "$(line_of 'say \"Done\.')" ] && echo yes || echo no )"
check "the two apps are no longer quit by Apple Event" 0 \
  "$(grep -c 'quit app "AeroSpace"\|quit app "Hammerspoon"' "$ROOT/install.sh")"

echo "the config posts no synthetic event (the Accessibility (Events) request):"
LUA="${HAMMERSPOON_LUA:-$ROOT/hammerspoon/init.lua}"
check "Hammerspoon posts no keystroke" 0 "$(grep -c 'hs.eventtap.keyStroke' "$LUA")"
check "the Ghostty reload still clicks Reload Configuration" 1 \
  "$(grep -c 'selectMenuItem({ "Ghostty", "Reload Configuration" })' "$LUA")"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
