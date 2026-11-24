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

echo "docs deploy:"
check "no hand-deploy command in the docs README" 0 "$(grep -ciE 'vercel (deploy|--prod)' "$SITE/README.md")"
check "CONTEXT.md names the docs Vercel project" yes \
  "$(grep -q 'omarchy4mac-docs' "$ROOT/CONTEXT.md" && echo yes || echo no)"
check "CONTEXT.md names the production branch" yes \
  "$(grep -q 'production branch' "$ROOT/CONTEXT.md" && echo yes || echo no)"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
