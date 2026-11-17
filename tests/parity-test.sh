#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PAGE="$ROOT/docs-site/content/docs/parity.mdx"
CHECKLIST="$ROOT/docs/parity-v4.md"
fails=0

check() {
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 is not installed; it reads the parity table"
  exit 1
fi

VER="$(cat "$ROOT/OMARCHY_VERSION")"

COUNTS="$(python3 - "$PAGE" <<'PY'
import re, sys

rows = [l for l in open(sys.argv[1], encoding="utf-8").read().splitlines()
        if l.startswith("|") and not re.match(r"^\|\s*[-:]", l)
        and not l.startswith("| Omarchy Quattro has")]

def mark(row):
    return [c.strip() for c in row.strip().strip("|").split("|")][2]

tally = {}
for row in rows:
    tally[mark(row)] = tally.get(mark(row), 0) + 1

matched, partial, missing = tally.get("✅", 0), tally.get("⚠️", 0), tally.get("❌", 0)
scored = matched + partial + missing
if not scored:
    sys.exit(1)
print(int((matched + 0.5 * partial) * 100 / scored + 0.5), matched, partial, missing, scored)
PY
)" || { echo "FAIL: could not read the parity table in $PAGE"; exit 1; }

read -r PCT MATCHED PARTIAL MISSING SCORED <<< "$COUNTS"

echo "parity against Omarchy v$VER: $PCT% ($MATCHED/$PARTIAL/$MISSING of $SCORED):"
check "the page names the release and the counted score" \
  grep -qF "**$PCT%** of Omarchy v$VER (Quattro)" "$PAGE"
check "the page's counts are the table's" \
  bash -c "grep -qF 'That is $MATCHED matched, $PARTIAL partial, $MISSING' '$PAGE' && grep -qF 'not portable, out of $SCORED scored.' '$PAGE'"
check "the page description carries the release and the score" \
  grep -qF "description: \"$PCT% of Omarchy v$VER, scored feature by feature" "$PAGE"
check "the README names the release" grep -qF "Omarchy v$VER" "$ROOT/README.md"
check "the README names the score" grep -qF "$PCT%" "$ROOT/README.md"
check "the checklist names the release and the score" \
  bash -c "grep -qF 'v$VER' '$CHECKLIST' && grep -qF '$PCT%' '$CHECKLIST'"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
