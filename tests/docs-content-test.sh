#!/bin/bash
# Two pages of the docs site are built from files in the repo: the changelog
# from CHANGELOG.md, and the parity checklist from docs/parity-v4.md. They are
# committed, so the site builds on its own (Vercel uploads only docs-site/), and
# this is the test that keeps them from going stale: sync-content.mjs --check
# rebuilds both in memory and fails when a page no longer matches its source.
#
#   tests/docs-content-test.sh
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
