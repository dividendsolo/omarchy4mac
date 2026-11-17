#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT
fails=0

command -v bun >/dev/null || { echo "FAIL: bun is not installed (brew install oven-sh/bun/bun)"; exit 1; }

check() {
  local d="$1"; shift
  if "$@" >"$OUT" 2>&1; then echo "  ok    $d"
  else echo "  FAIL  $d"; cat "$OUT"; fails=$((fails + 1)); fi
}

echo "comments:"
checker_tests() { ( cd "$ROOT/tools/no-comments" && bun run test ); }
check "no comment in any tracked file" "$ROOT/bin/no-comments"
check "no comment-like line the checker misses" bun "$ROOT/tools/no-comments/backstop.ts" "$ROOT"
check "the checker's own tests" checker_tests

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
