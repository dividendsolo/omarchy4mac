#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

STEP="$(sed -n '/^link() {$/,/^done$/p' "$ROOT/install.sh")"
[[ -n "$STEP" ]] || { echo "FAIL: no link step in install.sh"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home"

run_link() {
  HOME="$TMP/home" DIR="$ROOT" SRC="$ROOT" DRY=0 STAMP=test \
    bash -c '
set -euo pipefail
TILDE="~"
say() { printf "==> %s\n" "$*"; }
warn() { printf "  ! %s\n" "$*"; }
run() { if [ "$DRY" = 1 ]; then echo "    would: $*"; else "$@"; fi; }
'"$STEP"'
' 2>&1
}

echo "A second install run links over what is already linked (omarchy4mac#109):"

first="$(run_link)"; first_status=$?
check "the first run exits 0" "0" "$first_status"
check "the first run links the config" "yes" "$([ -L "$TMP/home/.aerospace.toml" ] && echo yes || echo no)"

second="$(run_link)"; second_status=$?
check "the second run exits 0" "0" "$second_status"
check "the second run leaves the link in place" "yes" "$([ -L "$TMP/home/.aerospace.toml" ] && echo yes || echo no)"

[[ "$fails" -eq 0 ]] && echo PASS || { echo "FAIL: $fails check(s)"; exit 1; }
