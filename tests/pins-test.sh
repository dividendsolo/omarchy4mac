#!/bin/bash
# Checks that code fetched from omacom at install or sync time is pinned to a
# recorded commit, never a branch head (#45): OMARCHY_COMMIT for `theme --sync`,
# `cargo install --rev` for ttfx.
#
#   tests/pins-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

# The manual install steps left the README for the docs page when the docs site
# landed (#73).
INSTALL_DOC="$ROOT/docs-site/content/docs/install.mdx"
echo "pins:"
check "OMARCHY_COMMIT holds one full commit SHA" grep -qxE '[0-9a-f]{40}' "$ROOT/OMARCHY_COMMIT"
check "the docs install page pins ttfx too" \
  grep -qE 'cargo install --git https://github.com/omacom/ttfx --rev [0-9a-f]{40}( |$)' "$INSTALL_DOC"
check "no unpinned ttfx install anywhere" \
  bash -c "! grep -rnE 'cargo install --git https://github.com/omacom/ttfx( *$| *&&)' '$ROOT/install.sh' '$ROOT/docs-site/content/docs'"
check "install.sh pins ttfx with cargo install --rev <sha>" \
  grep -qE 'cargo install --git https://github.com/omacom/ttfx --rev [0-9a-f]{40}( |$)' "$ROOT/install.sh"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
