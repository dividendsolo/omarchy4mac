#!/bin/bash
# The docs site's front page has one job: get a reader into the docs. This
# checks that the way in is easy to find (#73 review):
#
#   - no paragraph on the page is smaller than 16px (no text-xs or text-sm <p>)
#   - the link to /docs is its own element, not a word inside a paragraph
#
#   tests/docs-home-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PAGE="${PAGE:-$HERE/../docs-site/app/(home)/page.tsx}"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

echo "docs home page:"
check "no paragraph is under 16px" 0 "$(grep -cE '<p [^>]*text-(xs|sm)\b' "$PAGE")"
check "the docs link is not inside a paragraph" 0 \
  "$(python3 - "$PAGE" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
print(sum('href="/docs"' in p for p in re.findall(r"<p\b.*?</p>", src, re.S)))
PY
)"
check "the page links to /docs" 1 "$(grep -c 'href="/docs"' "$PAGE")"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
