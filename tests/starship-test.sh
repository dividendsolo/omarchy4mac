#!/bin/bash
# Checks the Starship prompt is Omarchy 4's: terminal (ANSI) colors only, so
# the prompt follows every theme switch, and Omarchy's ❯ prompt symbol.
# Renders the real prompt for a throwaway git repo with this config.
#
#   tests/starship-test.sh
#   STARSHIP_TOML=/path/to/starship.toml tests/starship-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOML="${STARSHIP_TOML:-$HERE/../starship/starship.toml}"
fails=0

check() { # check <description> <test command...>
  local d="$1"; shift
  if "$@"; then echo "  ok    $d"; else echo "  FAIL  $d"; fails=$((fails + 1)); fi
}

command -v starship >/dev/null || { echo "starship not installed"; exit 1; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/myrepo/src" && git -C "$T/myrepo" init -q -b main
: > "$T/myrepo/src/new-file"   # untracked: git_status has something to show
cd "$T/myrepo/src"
PROMPT_OUT="$(STARSHIP_CONFIG="$TOML" STARSHIP_SHELL= starship prompt --status 0 2>/dev/null)"
ERR_OUT="$(STARSHIP_CONFIG="$TOML" STARSHIP_SHELL= starship prompt --status 1 2>/dev/null)"

echo "prompt in a git repo:"
check "uses no fixed 24-bit colors (38;2;…)" bash -c '! grep -q $'"'"'\033\[[0-9;]*38;2;'"'"' <<<"$1"' _ "$PROMPT_OUT"
check "uses the terminal's cyan (ANSI 36)" grep -q $'\033\[[0-9;]*36m' <<<"$PROMPT_OUT"
check "shows the repo root and the folder (myrepo/src)" grep -q 'myrepo.*src' <<<"$PROMPT_OUT"
check "shows the branch" grep -q 'main' <<<"$PROMPT_OUT"
check "prompt symbol is ❯" grep -q '❯' <<<"$PROMPT_OUT"
check "error symbol is ✗" grep -q '✗' <<<"$ERR_OUT"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
