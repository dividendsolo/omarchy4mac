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

for f in "Dockerfile" "nginx.conf" "config/deploy.yml" "public/index.html"; do
  got="missing"
  [[ -f "$SITE/$f" ]] && got="present"
  check "$f exists" "present" "$got"
done

got="no"
grep -q "output: 'export'" "$SITE/next.config.mjs" 2>/dev/null && got="yes"
check "the site builds as a static export" "yes" "$got"

got="no"
grep -q 'staticGET' "$SITE/app/api/search/route.ts" 2>/dev/null && got="yes"
check "the search route exports a static GET" "yes" "$got"

got="no"
grep -q 'url=/docs' "$SITE/public/index.html" 2>/dev/null && got="yes"
check "the root page sends a reader to /docs" "yes" "$got"

got=$(grep -E '^service:' "$SITE/config/deploy.yml" 2>/dev/null | awk '{print $2}')
check "the Kamal service is named" "omarchy4mac-docs" "${got:-none}"

got="no"
grep -q 'omarchy4mac.dividendsolo.com' "$SITE/config/deploy.yml" 2>/dev/null && got="yes"
check "deploy.yml serves the docs hostname" "yes" "$got"

got=$(grep -A3 'healthcheck:' "$SITE/config/deploy.yml" 2>/dev/null | grep 'path:' | awk '{print $2}')
check "the healthcheck path is set" "/up" "${got:-none}"

got="no"
grep -q 'location = /up' "$SITE/nginx.conf" 2>/dev/null && got="yes"
check "nginx answers the healthcheck" "yes" "$got"

got="no"
grep -q 'ezio' "$SITE/config/deploy.yml" 2>/dev/null && got="yes"
check "the app deploys to ezio" "yes" "$got"

got=$(grep -A2 '^ssh:' "$SITE/config/deploy.yml" 2>/dev/null | grep 'user:' | awk '{print $2}')
check "kamal connects to ezio as div, not root" "div" "${got:-none}"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
