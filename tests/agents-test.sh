#!/bin/bash
# Checks the bar's agents items (sketchybar/plugins/agents.sh and
# bin/omarchy-agent-usage): Claude, Codex and Grok limits each show a meter
# and a reset time, and a provider with no login is hidden. sketchybar,
# security (the Keychain) and codex are stubs on PATH, HOME is a scratch
# folder, and Claude's and Grok's endpoints are answered in-process, so no
# real login or network is touched.
#
#   tests/agents-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
USAGE="$HERE/../bin/omarchy-agent-usage"
fails=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/repo/sketchybar" "$TMP/repo/bin"
# colors.sh is written by bin/theme and is not in git, so the test brings its own.
printf 'export ACCENT="0xff00ff00"\nexport FG="0xffffffff"\n' > "$TMP/repo/sketchybar/colors.sh"
ln -s "$USAGE" "$TMP/repo/bin/omarchy-agent-usage"
cat > "$TMP/bin/sketchybar" <<'STUB'
#!/bin/bash
echo "$*" >> "$AGENTS_TEST_LOG"
STUB
# The Keychain: Claude Code's login when CLAUDE_TEST_TOKEN is set, else none.
cat > "$TMP/bin/security" <<'STUB'
#!/bin/bash
[ -n "${CLAUDE_TEST_TOKEN:-}" ] || exit 44
echo "{\"claudeAiOauth\": {\"accessToken\": \"$CLAUDE_TEST_TOKEN\"}}"
STUB
# Codex's app-server: answers initialize, then account/rateLimits/read with
# CODEX_TEST_LIMITS.
cat > "$TMP/bin/codex" <<'STUB'
#!/bin/bash
while read -r line; do
  case "$line" in
    *'"id": 1,'*) echo '{"method": "note", "params": {}}'; echo '{"id": 1, "result": {}}' ;;
    *'"id": 2,'*) echo "{\"id\": 2, \"result\": $CODEX_TEST_LIMITS}"; exit 0 ;;
  esac
done
STUB
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:$PATH"

check() { # check <description> <expected regex> <actual>
  if [[ "$3" =~ $2 ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected /$2/, got '$3')"; fails=$((fails + 1)); fi
}

fresh_home() { rm -rf "$TMP/home"; mkdir -p "$TMP/home"; export HOME="$TMP/home"; unset CODEX_HOME GROK_HOME CLAUDE_TEST_TOKEN; }

plugin() { # plugin <provider>: what the bar item was set to
  : > "$TMP/log"
  AGENTS_TEST_LOG="$TMP/log" CONFIG_DIR="$TMP/repo/sketchybar" NAME="agents.$1" \
    bash "$HERE/../sketchybar/plugins/agents.sh"
  cat "$TMP/log"
}

# macOS's /bin/bash 3.2 brace-expands the commas of a "{..., ...}" argument
# inside "$( )", so every JSON answer is built in $answer first.
# In-process run with Claude's and Grok's HTTPS answered from ANSWERS:
# url substring -> JSON body, or an HTTP status number.
inproc() { # inproc <provider> <answers json>: the collector's line, or "exit 1"
  python3 - "$USAGE" "$1" "$2" <<'PY'
import importlib.machinery, importlib.util, io, json, sys, urllib.error
sys.dont_write_bytecode = True  # no __pycache__ in bin/, which install.sh links whole
path, provider, answers = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
loader = importlib.machinery.SourceFileLoader("usage", path)
module = importlib.util.module_from_spec(importlib.util.spec_from_loader("usage", loader))
loader.exec_module(module)
def urlopen(request, timeout=None):
  for part, answer in answers.items():
    if part in request.full_url:
      if isinstance(answer, int):
        raise urllib.error.HTTPError(request.full_url, answer, "no", {}, None)
      return io.BytesIO(json.dumps(answer).encode())
  raise urllib.error.URLError("offline")
module.urllib.request.urlopen = urlopen
sys.argv = ["omarchy-agent-usage", provider]
try:
  module.main()
except SystemExit as stop:
  print("exit %s" % stop.code)
PY
}

iso() { python3 -c "import datetime as d,sys; print((d.datetime.now(d.timezone.utc)+d.timedelta(hours=float(sys.argv[1]))).isoformat())" "$1"; }
epoch() { python3 -c "import time,sys; print(int(time.time()+float(sys.argv[1])*3600))" "$1"; }
TIME='[0-9]{1,2}:[0-9]{2}[ap]m|[A-Z][a-z]{2}'

echo "no login: every provider hidden"
fresh_home
for p in claude codex grok; do
  check "$p collector exits 1" '^$' "$("$USAGE" "$p"; [ $? -eq 1 ] || echo "exit not 1")"
  check "$p item hidden" "^--set agents.$p drawing=off$" "$(plugin "$p")"
done
mkdir -p "$HOME/.codex"; echo '{"auth_mode": "apikey", "OPENAI_API_KEY": "sk-test"}' > "$HOME/.codex/auth.json"
check "codex API key login (no plan limits) hidden" "^--set agents.codex drawing=off$" "$(plugin codex)"
mkdir -p "$HOME/.grok"; echo "{\"x\": {\"key\": \"k\", \"expires_at\": \"$(iso -800)\", \"refresh_token\": \"r\"}}" > "$HOME/.grok/auth.json"
check "grok sign-in past its 30 days hidden" "^exit 1$" "$(inproc grok '{}')"

echo "claude"
fresh_home; export CLAUDE_TEST_TOKEN=t
answer="{\"oauth/usage\": {\"five_hour\": {\"utilization\": 42, \"resets_at\": \"$(iso 2)\"}, \"seven_day\": {\"utilization\": 18, \"resets_at\": \"$(iso 72)\"}}}"
check "5h and 7d meters with reset times" "^5h ▰▰▱▱▱ 42% ($TIME) · 7d ▰▱▱▱▱ 18% ($TIME)$" "$(inproc claude "$answer")"
check "offline: the cached answer stands" "^5h ▰▰▱▱▱ 42% ($TIME) · 7d" "$(python3 -c '
import json,sys,time; p=sys.argv[1]; d=json.load(open(p)); d["checkedAt"]=0; json.dump(d,open(p,"w"))' "$HOME/.cache/omarchy/agent-usage/claude-limits.json"; inproc claude '{}')"
answer="{\"oauth/usage\": {\"five_hour\": {\"utilization\": 90, \"resets_at\": \"$(iso -1)\"}}}"
check "an ended window shows 0% and no time" "^5h ▱▱▱▱▱ 0%$" "$(rm -rf "$HOME/.cache"; inproc claude "$answer")"
check "logged out after an answer: hidden, cache ignored" "^exit 1$" "$(unset CLAUDE_TEST_TOKEN; inproc claude '{}')"

echo "codex"
fresh_home; mkdir -p "$HOME/.codex"; echo '{"tokens": {"access_token": "a"}}' > "$HOME/.codex/auth.json"
export CODEX_TEST_LIMITS="{\"rateLimits\": {\"primary\": {\"usedPercent\": 42, \"windowDurationMins\": 300, \"resetsAt\": $(epoch 2)}, \"secondary\": {\"usedPercent\": 18, \"windowDurationMins\": 10080, \"resetsAt\": $(epoch 72)}}}"
check "5h and 7d meters with reset times, from the app-server" "^5h ▰▰▱▱▱ 42% ($TIME) · 7d ▰▱▱▱▱ 18% ($TIME)$" "$("$USAGE" codex)"
check "item shows them" "drawing=on icon.color=0xff00ff00 label=5h ▰▰▱▱▱ 42%" "$(plugin codex)"
rm -rf "$HOME/.cache"
export CODEX_TEST_LIMITS="{\"rateLimitsByLimitId\": {\"codex\": {\"individualLimit\": {\"limit\": 200, \"used\": 150, \"resetsAt\": $(epoch 100)}}}}"
check "a Business spend cap alone" "^\\$ ▰▰▰▰▱ 75% ($TIME)$" "$("$USAGE" codex)"

echo "grok"
fresh_home; mkdir -p "$HOME/.grok"; echo "{\"https://x.ai\": {\"key\": \"k\", \"expires_at\": \"$(iso 5)\"}}" > "$HOME/.grok/auth.json"
answer="{\"format=credits\": {\"config\": {\"creditUsagePercent\": 60, \"currentPeriod\": {\"type\": \"BILLING_PERIOD_TYPE_WEEKLY\", \"end\": \"$(iso 50)\"}}}}"
check "weekly credits meter with reset time" "^7d ▰▰▰▱▱ 60% ($TIME)$" "$(inproc grok "$answer")"
rm -rf "$HOME/.cache"
answer="{\"format=credits\": {\"config\": {\"currentPeriod\": {\"type\": \"BILLING_PERIOD_TYPE_WEEKLY\", \"end\": \"$(iso 50)\"}}}}"
check "a fresh week (no percentage) reads 0%" "^7d ▱▱▱▱▱ 0% ($TIME)$" "$(inproc grok "$answer")"
rm -rf "$HOME/.cache"
answer="{\"format=credits\": {\"config\": {\"isUnifiedBillingUser\": true, \"currentPeriod\": {\"end\": \"$(iso 50)\"}}}, \"v1/billing\": {\"config\": {\"monthlyLimit\": {\"val\": 10}, \"used\": {\"val\": 10}, \"billingPeriodEnd\": \"$(iso 300)\"}}}"
check "unified billing: the monthly quota" "^mo ▰▰▰▰▰ 100% ($TIME)$" "$(inproc grok "$answer")"
rm -rf "$HOME/.cache"
check "a refused sign-in is hidden" "^exit 1$" "$(inproc grok '{"format=credits": 401}')"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
