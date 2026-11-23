#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

echo "Intel Macs: Homebrew lives in /usr/local, Apple Silicon in /opt/homebrew (2026-11-23):"
pinned="$(cd "$ROOT" && grep -rnE '/opt/homebrew/bin/[a-z]' aerospace hammerspoon sketchybar bin install.sh \
  | grep -vE 'PATH=|PATH:|shellenv|-x /opt/homebrew|:-/opt/homebrew|\|\| echo /opt/homebrew' || true)"
check "no command is called by its Apple Silicon path alone" "" "$pinned"

path_line="$(python3 - "$ROOT/aerospace/aerospace.toml" <<'PY'
import sys, tomllib
print(tomllib.load(open(sys.argv[1], "rb")).get("exec", {}).get("env-vars", {}).get("PATH", ""))
PY
)"
check "AeroSpace's exec PATH has both Homebrew prefixes" \
  "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:\${PATH}" "$path_line"

grep -qE '^hs\.execute\("export PATH=' "$ROOT/hammerspoon/init.lua" 2>/dev/null \
  || grep -qE '^local BREW_PATH = "/opt/homebrew/bin:/usr/local/bin' "$ROOT/hammerspoon/init.lua"
check "Hammerspoon puts both Homebrew prefixes on its commands' PATH" "0" "$?"

for f in bin/theme-appearance-watch bin/omarchy-launch-screensaver bin/omarchy-screensaver; do
  grep -qE '^export PATH=.*/usr/local/bin' "$ROOT/$f"
  check "$f searches /usr/local/bin too" "0" "$?"
done

grep -qE 'eval "\$\(/usr/local/bin/brew shellenv\)"|brew shellenv' "$ROOT/install.sh" \
  && grep -qE '/usr/local/bin/brew' "$ROOT/install.sh"
check "install.sh finds a fresh Homebrew on Intel too" "0" "$?"

exit $fails
