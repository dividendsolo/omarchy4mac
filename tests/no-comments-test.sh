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

gap_repo() {
  local dir="$1"
  mkdir -p "$dir/aerospace" "$dir/tests"
  cp "$ROOT/aerospace/aerospace.toml" "$dir/aerospace/aerospace.toml"
  printf "%s\n" "luajit - <<'LUAEOF'" 'local s = "-- in a string"' 'LUAEOF' > "$dir/tests/x-test.sh"
  git -C "$dir" init -q
}
gaps_found() { ! python3 "$ROOT/tests/comment-gaps.py" "$1"; }
trailing_toml() {
  local dir; dir="$(mktemp -d)"; gap_repo "$dir"
  printf "%s\n" "outer.extra = 8   # x" >> "$dir/aerospace/aerospace.toml"
  git -C "$dir" add -A; gaps_found "$dir"; local r=$?; rm -rf "$dir"; return $r
}
heredoc_lua() {
  local dir; dir="$(mktemp -d)"; gap_repo "$dir"
  printf "%s\n" "luajit - <<'LUAEOF'" 'local x = 1 -- why' 'LUAEOF' >> "$dir/tests/x-test.sh"
  git -C "$dir" add -A; gaps_found "$dir"; local r=$?; rm -rf "$dir"; return $r
}
clean_copy() {
  local dir; dir="$(mktemp -d)"; gap_repo "$dir"
  git -C "$dir" add -A; python3 "$ROOT/tests/comment-gaps.py" "$dir"; local r=$?; rm -rf "$dir"; return $r
}
check "no trailing TOML comment or Lua comment in a here-document" python3 "$ROOT/tests/comment-gaps.py" "$ROOT"
check "the gap check passes strings that hold # and --" clean_copy
check "the gap check fails on a trailing # in aerospace.toml" trailing_toml
check "the gap check fails on a -- comment in a Lua here-document" heredoc_lua

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
