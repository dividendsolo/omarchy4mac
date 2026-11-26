#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

binding="$(grep -E '^cmd-shift-slash *=' "$ROOT/aerospace/aerospace.toml" | sed -E "s/^[^=]*= *'(.*)'/\1/")"

echo "docs pages vs the ⌘⇧/ binding ($binding):"
case "$binding" in
  *"open -a 1Password"*)
    hits="$(grep -n '⌘⇧/' "$ROOT"/docs-site/content/docs/*.md "$ROOT"/docs-site/content/docs/*.mdx \
      | grep -v '/changelog.md:' | grep -i 'menu')"
    if [ -n "$hits" ]; then
      echo "FAIL: a docs page says ⌘⇧/ searches menus, but AeroSpace sends it to 1Password:"
      echo "$hits"
      exit 1
    fi
    ;;
  *)
    echo "FAIL: cmd-shift-slash is '$binding'; update this test to match the key"
    exit 1
    ;;
esac
echo "PASS"
