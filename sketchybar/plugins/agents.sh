#!/usr/bin/env bash
# Coding-agent usage, like Omarchy's agents widget (v4.0.5): the Claude Code
# 5-hour and weekly limits with their reset times, from
# omarchy-agent-usage-claude. When the limits are unknown (logged out, offline,
# rate limited with no earlier answer), today's spend from the local session
# logs instead (ccusage reads ~/.claude/projects). Hidden when neither is there.
source "$CONFIG_DIR/colors.sh"

LIMITS="$("$HOME/.local/bin/omarchy-agent-usage-claude" 2>/dev/null)"
if [ -n "$LIMITS" ]; then
  sketchybar --set "$NAME" drawing=on icon="󰚩" icon.color="$ACCENT" label="$LIMITS" label.color="$FG"
  exit 0
fi

TODAY="$(date +%Y%m%d)"
COST="$(PATH="$HOME/.bun/bin:$PATH" bunx ccusage daily --json --since "$TODAY" 2>/dev/null \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(round(sum(x.get("totalCost",0) for x in d.get("daily",[]))))' 2>/dev/null)"
if [ -n "$COST" ] && [ "$COST" -gt 0 ]; then
  sketchybar --set "$NAME" drawing=on icon="󰚩" icon.color="$ACCENT" label="\$$COST" label.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
