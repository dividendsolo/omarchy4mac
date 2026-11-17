#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/displays.sh"

PROVIDER="${NAME#agents.}"
NOTCH="agents_notch.$PROVIDER"
hide() { sketchybar --set "$NAME" drawing=off --set "$NOTCH" drawing=off; exit 0; }
show() {
  if [ "$DISPLAYS_OK" = 0 ]; then
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
