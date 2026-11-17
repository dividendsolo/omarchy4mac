#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

WORD='recolou?r'

echo "the current copy:"
FOUND="$(grep -rniE "$WORD" "$ROOT/README.md" "$ROOT/docs-site/content/docs" "$ROOT/docs-site/app" \
  --exclude=changelog.md --exclude-dir=node_modules --exclude-dir=.next | sed "s|$ROOT/||")"
check "no 'recolour' or 'recolor' in the README, the docs pages or the site" "" "$FOUND"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
