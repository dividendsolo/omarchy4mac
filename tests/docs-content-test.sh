#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "FAIL: node is not installed; the docs site needs it to build its pages"
  exit 1
fi

echo "docs pages vs the repo files:"
if ! node "$ROOT/docs-site/scripts/sync-content.mjs" --check; then
  echo "FAIL: a docs page is out of step with the repo"
  exit 1
fi
echo "PASS"
