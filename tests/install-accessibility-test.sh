#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

line() { grep -n "$1" "$ROOT/install.sh" | head -1 | cut -d: -f1; }

PERM="$(line '^say "One manual step: Accessibility for AeroSpace and Hammerspoon"$')"
[[ -n "$PERM" ]] || { echo "FAIL: no Accessibility step in install.sh"; exit 1; }

echo "Nothing starts AeroSpace or Hammerspoon before the Accessibility switches are on (omarchy4mac#111):"
for pat in '^say "Loading launchd agents"$' 'open -a Hammerspoon' 'open -a AeroSpace'; do
  at="$(line "$pat")"
  if [[ -n "$at" && "$at" -gt "$PERM" ]]; then
    echo "  ok    $pat runs after the Accessibility step"
  else
    echo "  FAIL  $pat starts at line ${at:-none}, before the Accessibility step at $PERM"
    fails=$((fails + 1))
  fi
done

echo "The step says how to add an app macOS has not listed yet:"
check "the step points at the + button" 1 "$(grep -c 'with + from /Applications' "$ROOT/install.sh")"

echo "System Settings stays open when there is no terminal to wait on:"
TTY="$(line 'if \[ -r /dev/tty \]; then')"
ELSE="$(awk -v from="$TTY" 'NR > from && /^  else$/ { print NR; exit }' "$ROOT/install.sh")"
QUIT="$(line "quit app \"System Settings\"")"
RET="$(line 'read -r _ </dev/tty')"
if [[ -n "$QUIT" && -n "$RET" && -n "$ELSE" && "$QUIT" -gt "$RET" && "$QUIT" -lt "$ELSE" ]]; then
  echo "  ok    System Settings quits only in the /dev/tty branch, after the Return"
else
  echo "  FAIL  System Settings quits at line ${QUIT:-none}, outside the /dev/tty branch (${RET:-none}..${ELSE:-none})"
  fails=$((fails + 1))
fi

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
