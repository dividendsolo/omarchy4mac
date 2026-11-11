#!/bin/bash
# Checks Setup > Defaults > Agent (bin/omarchy-default-agent, Omarchy 4.5,
# omacom/omarchy#6950): choosing an agent that is not installed opens Ghostty
# to install it, the default changes only when the install succeeds, and an
# installed agent becomes the default at once. Runs in a throwaway HOME with
# open, brew, npm, curl and the login zsh stubbed, so nothing is installed.
#
#   tests/default-agent-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../bin/omarchy-default-agent"
fails=0
check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Only the system tools and the stubs: the agents on this machine stay out of reach.
export HOME="$TMP/home" HOMEBREW_PREFIX="$TMP/brew" PATH="/usr/bin:/bin"
BIN="$HOME/.local/bin" LOG="$TMP/log" FILE="$HOME/.config/omarchy/defaults/agent"
mkdir -p "$BIN" "$HOMEBREW_PREFIX/bin" "${FILE%/*}"
# Each stub logs its command line; brew and npm exit with $INSTALL_EXIT.
for tool in open brew npm; do
  printf '#!/bin/bash\necho "%s $*" >>"%s"\nexit ${INSTALL_EXIT:-0}\n' "$tool" "$LOG" >"$BIN/$tool"
done
printf '#!/bin/bash\necho "curl $*" >>"%s"\necho "exit ${INSTALL_EXIT:-0}"\n' "$LOG" >"$BIN/curl"
# The login zsh sees only the stubs, never the agents on this machine.
printf '#!/bin/bash\nPATH="%s:/usr/bin:/bin" exec /bin/zsh -f -c "${@: -1}"\n' "$BIN" >"$BIN/zsh"
chmod +x "$BIN"/*

reset() { echo claude >"$FILE"; : >"$LOG"; rm -f "$BIN/codex"; }

echo "a missing agent is installed when chosen:"
reset
out=$("$SCRIPT" codex); status=$?
check "menu pick exits 0" 0 "$status"
check "menu pick says it installs" "Agent|||Installing Codex in Ghostty" "$out"
check "menu pick opens Ghostty on the install" \
  "open -na Ghostty --args -e $BIN/omarchy-tui $BIN/omarchy-default-agent --install codex" "$(cat "$LOG")"
check "menu pick keeps the default until the install ends" claude "$(cat "$FILE")"

reset
out=$("$SCRIPT" --install codex); status=$?
check "install exits 0" 0 "$status"
check "install runs brew" "brew install --cask codex" "$(cat "$LOG")"
check "install makes it the default" codex "$(cat "$FILE")"

reset
out=$(INSTALL_EXIT=1 "$SCRIPT" --install codex 2>&1); status=$?
check "failed install exits 1" 1 "$status"
check "failed install keeps the default" claude "$(cat "$FILE")"

echo "each agent's installer:"
for pair in "claude|brew install --cask claude-code" "grok|npm install -g @xai-official/grok" \
  "openclaw|npm install -g openclaw@latest" \
  "hermes|curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"; do
  reset; echo codex >"$FILE"
  "$SCRIPT" --install "${pair%%|*}" >/dev/null 2>&1
  check "${pair%%|*} installs with ${pair#*|}" "${pair#*|}" "$(cat "$LOG")"
  check "${pair%%|*} is then the default" "${pair%%|*}" "$(cat "$FILE")"
done

echo "an installed agent:"
reset
printf '#!/bin/bash\n' >"$BIN/codex"; chmod +x "$BIN/codex"
out=$("$SCRIPT" codex)
check "becomes the default at once" codex "$(cat "$FILE")"
check "installs nothing" "" "$(cat "$LOG")"
check "says so" "Agent|||Codex is the default agent" "$out"

(( fails == 0 )) && echo PASS || { echo "FAIL: $fails check(s)"; exit 1; }
