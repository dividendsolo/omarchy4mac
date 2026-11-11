#!/usr/bin/env bash
# Coding-agent limits, like Omarchy 4.5's agents panel: one item per provider
# (agents.claude, agents.codex, agents.grok), each limit a meter with its
# reset time, from omarchy-agent-usage. A provider with no login is hidden
# (the collector exits 1). When Claude's limits are unknown (offline, rate
# limited with no earlier answer), today's spend from the local session logs
# instead (ccusage reads ~/.claude/projects). Hidden when neither is there.
source "$CONFIG_DIR/colors.sh"

PROVIDER="${NAME#agents.}"
# The collector runs from the clone ~/.config/sketchybar links to, so a
# `git pull` alone brings a new one.
REPO="$(cd -P "$CONFIG_DIR/.." && pwd)"
LIMITS="$("$REPO/bin/omarchy-agent-usage" "$PROVIDER" 2>/dev/null)" || { sketchybar --set "$NAME" drawing=off; exit 0; }
if [ -n "$LIMITS" ]; then
  sketchybar --set "$NAME" drawing=on icon.color="$ACCENT" label="$LIMITS" label.color="$FG"
  exit 0
fi

COST=""
if [ "$PROVIDER" = claude ]; then
  TODAY="$(date +%Y%m%d)"
  COST="$(PATH="$HOME/.bun/bin:$PATH" bunx ccusage daily --json --since "$TODAY" 2>/dev/null \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(round(sum(x.get("totalCost",0) for x in d.get("daily",[]))))' 2>/dev/null)"
fi
if [ -n "$COST" ] && [ "$COST" -gt 0 ]; then
  sketchybar --set "$NAME" drawing=on icon.color="$ACCENT" label="\$$COST" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
