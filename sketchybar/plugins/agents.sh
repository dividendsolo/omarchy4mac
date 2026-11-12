#!/usr/bin/env bash
# Coding-agent limits, like Omarchy 4.5's agents panel: one item per provider
# (agents.claude, agents.codex, agents.grok), each limit a meter with its
# reset time, from omarchy-agent-usage. A provider with no login is hidden
# (the collector exits 1). When Claude's limits are unknown (offline, rate
# limited with no earlier answer), today's spend from the local session logs
# instead (ccusage reads ~/.claude/projects). Hidden when neither is there.
#
# The full label shows on the external screens. On the notched built-in
# screen it ran under the notch (#70), so a copy there (agents_notch.<provider>)
# shows the percentages only: "14% · 97%".
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

PROVIDER="${NAME#agents.}"
NOTCH="agents_notch.$PROVIDER"
hide() { sketchybar --set "$NAME" drawing=off --set "$NOTCH" drawing=off; exit 0; }
show() { # show <full label> <built-in screen label>
  if [ "$DISPLAYS_OK" = 0 ]; then
    # A failed display lookup: keep where each is drawn, refresh the labels.
    sketchybar --set "$NAME" label="$1" --set "$NOTCH" label="$2"
    exit 0
  fi
  local item displays label
  for item in "$NAME" "$NOTCH"; do
    if [ "$item" = "$NAME" ]; then displays="$OTHERS" label="$1"; else displays="$BUILTIN" label="$2"; fi
    if [ "$displays" = "-" ]; then
      sketchybar --set "$item" drawing=off
    else
      sketchybar --set "$item" drawing=on associated_display="$displays" icon.color="$ACCENT" label="$label" label.color="$FG"
    fi
  done
  exit 0
}

# The collector runs from the clone ~/.config/sketchybar links to, so a
# `git pull` alone brings a new one.
REPO="$(cd -P "$CONFIG_DIR/.." && pwd)"
LIMITS="$("$REPO/bin/omarchy-agent-usage" "$PROVIDER" 2>/dev/null)" || hide
[ -n "$LIMITS" ] && show "$LIMITS" "$(grep -oE '[0-9]+%' <<<"$LIMITS" | paste -sd '|' - | sed 's/|/ · /g')"

COST=""
if [ "$PROVIDER" = claude ]; then
  TODAY="$(date +%Y%m%d)"
  COST="$(PATH="$HOME/.bun/bin:$PATH" bunx ccusage daily --json --since "$TODAY" 2>/dev/null \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(round(sum(x.get("totalCost",0) for x in d.get("daily",[]))))' 2>/dev/null)"
fi
[ -n "$COST" ] && [ "$COST" -gt 0 ] && show "\$$COST" "\$$COST"
hide
