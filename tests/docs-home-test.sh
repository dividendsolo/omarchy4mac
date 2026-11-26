#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SITE="$ROOT/docs-site"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

echo "docs front page:"
check "there is no front page" no "$([[ -e "$SITE/app/(home)" ]] && echo yes || echo no)"
check "/ redirects to /docs" 1 \
  "$(grep -cE "source: '/', destination: '/docs'" "$SITE/next.config.mjs")"
check "the first docs page opens on the desktop screenshot" "/omarchy4mac-desktop.webp" \
  "$(awk '/^---$/ { fm++; next } fm >= 2 && NF { print; exit }' "$SITE/content/docs/index.mdx" |
     sed -nE 's/^!\[[^]]*\]\(([^)]+)\).*/\1/p')"

echo "docs address:"
check "no vercel.app address in the repo" "" \
  "$(git -C "$ROOT" grep -l 'vercel\.app' -- . ':!tests/docs-home-test.sh' | paste -sd' ' -)"
check "the README links to the docs domain" yes \
  "$([[ "$(grep -c 'https://omarchy4mac.dividendsolo.com' "$ROOT/README.md")" -ge 2 ]] && echo yes || echo no)"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
