#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

line() { grep -nE "$1" "$ROOT/install.sh" | head -1 | cut -d: -f1; }
linef() { grep -nF "$1" "$ROOT/install.sh" | head -1 | cut -d: -f1; }

STAR_TEXT="If it saved you an afternoon, a star helps: https://github.com/dividendsolo/omarchy4mac"

CLOSING="$(sed -n '/^say "Done\./,/^}$/p' "$ROOT/install.sh" | sed '$d')"
[[ -n "$CLOSING" ]] || { echo "FAIL: install.sh has no closing lines"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home"

run_closing() {
  HOME="$TMP/home" ORIG="$TMP/orig" FRESH="$1" bash -c '
say() { printf "==> %s\n" "$*"; }
'"$CLOSING"'
' 2>&1
}

echo "a fresh install ends with the ask (omarchy4mac#127):"
fresh="$(run_closing 1)"
check "the fresh run names the repo" 1 "$(printf '%s\n' "$fresh" | grep -cF "$STAR_TEXT")"
check "the ask is the last line" "$STAR_TEXT" "$(printf '%s\n' "$fresh" | grep -F 'star helps' | tail -1 | sed 's/^==> //')"

echo "an update run does not:"
update="$(run_closing 0)"
check "the update run stays quiet" 0 "$(printf '%s\n' "$update" | grep -cF 'star helps')"
check "the update run still prints the closing lines" 3 "$(printf '%s\n' "$update" | grep -c '^==>')"

echo "the wiring in install.sh:"
RERUN="$(linef 'Rerun this script to update')"
STAR="$(linef 'star helps')"
DRY="$(line '^  exit 0$')"
check "the ask is the card's exact wording" 1 "$(grep -cF "$STAR_TEXT" "$ROOT/install.sh")"
check "it sits after Rerun this script to update" "yes" \
  "$( [ -n "$STAR" ] && [ -n "$RERUN" ] && [ "$STAR" -gt "$RERUN" ] && echo yes || echo no )"
check "it sits after the dry-run exit" "yes" \
  "$( [ -n "$STAR" ] && [ -n "$DRY" ] && [ "$STAR" -gt "$DRY" ] && echo yes || echo no )"
check "FRESH starts at 0" 1 "$(grep -c '^FRESH=0$' "$ROOT/install.sh")"
check "the clone path sets FRESH=1" 1 "$(grep -c '^  FRESH=1$' "$ROOT/install.sh")"
UPD="$(linef 'Updating $DIR')"
BREW="$(linef 'say "brew bundle"')"
F1="$(line '^  FRESH=1$')"
check "FRESH=1 is on the clone path, not the update path" "yes" \
  "$( [ -n "$F1" ] && [ -n "$UPD" ] && [ -n "$BREW" ] && [ "$F1" -gt "$UPD" ] && [ "$F1" -lt "$BREW" ] && echo yes || echo no )"
check "the install stops on the first failure" 1 "$(grep -c '^set -euo pipefail$' "$ROOT/install.sh")"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
