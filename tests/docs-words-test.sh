#!/bin/bash
# "recolours" is the wrong word for what the script does: it themes the
# terminal, the editor, the bar and the wallpaper (James, 2026-11-13, #78).
# This fails when either spelling comes back into the current copy:
#
#   - README.md
#   - every page under docs-site/content/docs (changelog.md is history: it
#     keeps the words the release notes used at the time)
#   - the site itself, docs-site/app
#
#   tests/docs-words-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

# One pattern covers both spellings and their forms: recolour, recolours,
# recolor, recolors, recoloured.
WORD='recolou?r'

echo "the current copy:"
FOUND="$(grep -rniE "$WORD" "$ROOT/README.md" "$ROOT/docs-site/content/docs" "$ROOT/docs-site/app" \
  --exclude=changelog.md --exclude-dir=node_modules --exclude-dir=.next | sed "s|$ROOT/||")"
check "no 'recolour' or 'recolor' in the README, the docs pages or the site" "" "$FOUND"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
