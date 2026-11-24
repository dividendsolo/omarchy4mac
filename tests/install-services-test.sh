#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

STEP="$(sed -n '/^say "Starting services"$/,/^HEX=/p' "$ROOT/install.sh" | sed '$d')"
[[ -n "$STEP" ]] || { echo "FAIL: no Starting services step in install.sh"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STUBS="$TMP/bin"
LOG="$TMP/calls"
mkdir -p "$STUBS"

stub() { printf '#!/bin/bash\n%s\n' "$2" >"$STUBS/$1"; chmod +x "$STUBS/$1"; }
stub brew "echo \"brew \$*\" >>\"$LOG\""
stub open "echo \"open \$*\" >>\"$LOG\""

running() { stub pgrep "[ \"\$*\" = \"-x AeroSpace\" ] && exit $1; exit 1"; }
server() {
  if [[ "$1" == up ]]; then stub aerospace "echo \"aerospace \$*\" >>\"$LOG\""
  else stub aerospace "echo \"aerospace \$*\" >>\"$LOG\"
echo \"Can't connect to AeroSpace server. Is AeroSpace.app running?\" >&2
echo \"The operation couldn't be completed. (Network.NWError error 2 - No such file or directory)\" >&2
exit 1"
  fi
}

run_step() {
  : >"$LOG"
  PATH="$STUBS:/usr/bin:/bin" HOME="$TMP" DRY="$1" bash -c "
say() { echo \"==> \$*\"; }
run() { if [ \"\$DRY\" = 1 ]; then echo \"    would: \$*\"; else \"\$@\"; fi; }
$STEP" 2>&1
}

echo "First install: AeroSpace runs, its server does not answer yet (#105):"
running 0; server down
out="$(run_step 0)"
check "Starting services prints no error" "==> Starting services" "$out"
check "no reload is sent to a server that is not there" 0 "$(grep -c 'reload-config' "$LOG")"

echo "Rerun: AeroSpace runs and its server answers:"
running 0; server up
out="$(run_step 0)"
check "Starting services prints no error" "==> Starting services" "$out"
check "the config is reloaded" 1 "$(grep -c '^aerospace reload-config$' "$LOG")"
check "AeroSpace is not opened again" 0 "$(grep -c '^open -a AeroSpace$' "$LOG")"

echo "AeroSpace does not run:"
running 1; server down
out="$(run_step 0)"
check "Starting services prints no error" "==> Starting services" "$out"
check "AeroSpace is opened" 1 "$(grep -c '^open -a AeroSpace$' "$LOG")"
check "no reload is sent" 0 "$(grep -c 'reload-config' "$LOG")"

echo "Dry run:"
out="$(run_step 1)"
check "the dry run says what it would do" "==> Starting services
    would: brew services restart sketchybar
    would: brew services restart borders
    would: open -a Hammerspoon
    would: reload AeroSpace if it is running, otherwise launch it" "$out"
check "the dry run calls nothing" "" "$(cat "$LOG")"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
