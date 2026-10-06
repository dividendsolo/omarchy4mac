#!/usr/bin/env bash
# omarchy4mac uninstaller. Reverses install.sh and the changes `theme` makes.
#
#   ~/code/omarchy4mac/uninstall.sh --dry-run          # print what would happen, change nothing
#   ~/code/omarchy4mac/uninstall.sh                    # remove config, agents, shell hook, theme hooks
#   ~/code/omarchy4mac/uninstall.sh --purge            # also delete the clone, theme cache, wallpapers, logs, snapshot
#   ~/code/omarchy4mac/uninstall.sh --remove-packages  # also brew-uninstall the WM pieces
#
# Flags combine. Default mode is conservative: it only removes things that
# install.sh or `theme` created, restores the newest *.bak-<date> where
# install.sh moved your own file aside, puts back the Ghostty/btop/Neovim/
# Claude/Obsidian/wallpaper settings the installer snapshotted (if it did),
# and leaves brew packages alone.
#
# Env: OMARCHY4MAC_DIR overrides the clone location (default ~/code/omarchy4mac).
set -euo pipefail
TILDE="~"   # for ${path/#$HOME/$TILDE}; a bare ~ there expands back to $HOME in bash 5.2

DIR="${OMARCHY4MAC_DIR:-$HOME/code/omarchy4mac}"
DRY=0; PURGE=0; PKGS=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --purge) PURGE=1 ;;
    --remove-packages) PKGS=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[1;31m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then echo "    $*"; else "$@"; fi; }

[ "$DRY" = 1 ] && say "DRY RUN: nothing will be changed"

# ---- 1. Stop services and launchd agents ----------------------------------
say "Stopping services"
if command -v brew >/dev/null 2>&1; then
  for s in sketchybar borders; do
    brew list --formula "$s" >/dev/null 2>&1 && run brew services stop "$s" || true
  done
fi
# The keepalive agent relaunches AeroSpace, so unload agents before quitting it.
say "Unloading launchd agents"
for label in com.omarchy-mac.aerospace-keepalive com.omarchy-mac.theme-appearance; do
  plist="$HOME/Library/LaunchAgents/$label.plist"
  if [ -f "$plist" ]; then
    run launchctl unload "$plist" 2>/dev/null || true
    run rm -f "$plist"
  fi
done
for app in AeroSpace Hammerspoon; do
  pgrep -x "$app" >/dev/null 2>&1 && run osascript -e "quit app \"$app\"" || true
done
pgrep -f theme-appearance-listener >/dev/null 2>&1 && run pkill -f theme-appearance-listener || true

# ---- 2. Symlinks (only ones pointing into the clone) ----------------------
unlink_cfg() {  # unlink_cfg <absolute target>
  local dst="$1" bak
  if [ -L "$dst" ] && case "$(readlink "$dst")" in "$DIR"/*) true ;; *) false ;; esac; then
    run rm "$dst"
    # Restore the newest backup install.sh made, if any.
    bak="$(ls -1d "$dst".bak-* 2>/dev/null | sort | tail -n1 || true)"
    if [ -n "$bak" ]; then
      note "restoring $bak -> $dst"
      run mv "$bak" "$dst"
    fi
  fi
}
say "Removing config links"
unlink_cfg "$HOME/.aerospace.toml"
unlink_cfg "$HOME/.config/sketchybar"
unlink_cfg "$HOME/.config/borders"
unlink_cfg "$HOME/.config/starship.toml"
unlink_cfg "$HOME/.hammerspoon/init.lua"
if [ -d "$HOME/.local/bin" ]; then
  for f in "$HOME"/.local/bin/*; do
    [ -L "$f" ] || continue
    unlink_cfg "$f"
  done
fi
# Compiled listener is a real file, not a link.
[ -f "$HOME/.local/bin/theme-appearance-listener" ] && run rm -f "$HOME/.local/bin/theme-appearance-listener"
# ttfx link install.sh made (the cargo binary itself is only removed with --purge).
[ -L "$HOME/.local/bin/ttfx" ] && [ "$(readlink "$HOME/.local/bin/ttfx")" = "$HOME/.cargo/bin/ttfx" ] \
  && run rm "$HOME/.local/bin/ttfx"

# ---- 3. Shell hook --------------------------------------------------------
if [ -f "$HOME/.zshrc" ] && grep -qF "$DIR/zsh/omarchy.zsh" "$HOME/.zshrc"; then
  say "Removing omarchy.zsh from ~/.zshrc (backup: ~/.zshrc.bak-$STAMP)"
  if [ "$DRY" = 0 ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$STAMP"
    TARGET="$DIR/zsh/omarchy.zsh" python3 - "$HOME/.zshrc" <<'PY'
import os, sys
p, target = sys.argv[1], os.environ["TARGET"]
lines = open(p).read().split("\n")
out = [l for l in lines if l.strip() != "# omarchy4mac shell defaults" and target not in l]
# collapse the blank line install.sh added in front
text = "\n".join(out)
while "\n\n\n" in text: text = text.replace("\n\n\n", "\n\n")
open(p, "w").write(text)
PY
  fi
fi

# ---- 4. Undo what `theme` wrote into other apps ---------------------------
say "Reverting theme hooks"
GHOSTTY_MAC="$HOME/Library/Application Support/com.mitchellh.ghostty"
GHOSTTY_XDG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
for cfg in "$GHOSTTY_MAC/config" "$GHOSTTY_XDG/config"; do
  if [ -f "$cfg" ] && grep -qE '^[[:space:]]*theme[[:space:]]*=[[:space:]]*omarchy-' "$cfg"; then
    note "ghostty: dropping omarchy theme line from ${cfg/#$HOME/$TILDE}"
    [ "$DRY" = 1 ] || { cp "$cfg" "$cfg.bak-$STAMP"; perl -ni -e 'print unless /^[ \t]*theme[ \t]*=[ \t]*omarchy-/' "$cfg"; }
  fi
done
for d in "$GHOSTTY_MAC/themes" "$GHOSTTY_XDG/themes"; do
  ls "$d"/omarchy-* >/dev/null 2>&1 && run rm -f "$d"/omarchy-*
done

BTOP_CONFIG="$HOME/.config/btop/btop.conf"
if [ -f "$BTOP_CONFIG" ] && grep -qE '^[[:space:]]*color_theme[[:space:]]*=[[:space:]]*"omarchy-' "$BTOP_CONFIG"; then
  note "btop: color_theme back to Default"
  [ "$DRY" = 1 ] || perl -pi -e 's/^[ \t]*color_theme[ \t]*=[ \t]*"omarchy-.*$/color_theme = "Default"/' "$BTOP_CONFIG"
fi
ls "$HOME"/.config/btop/themes/omarchy-*.theme >/dev/null 2>&1 && run rm -f "$HOME"/.config/btop/themes/omarchy-*.theme

NVIM_THEME="$HOME/.config/nvim/lua/plugins/theme.lua"
if [ -f "$NVIM_THEME" ] && head -n1 "$NVIM_THEME" | grep -q 'Omarchy themes — generated by `theme'; then
  note "neovim: removing generated ${NVIM_THEME/#$HOME/$TILDE} (LazyVim falls back to tokyonight)"
  run rm -f "$NVIM_THEME"
fi

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -f "$CLAUDE_DIR/themes/omarchy.json" ] && run rm -f "$CLAUDE_DIR/themes/omarchy.json"
if [ -f "$CLAUDE_DIR/settings.json" ] && grep -q '"custom:omarchy"' "$CLAUDE_DIR/settings.json"; then
  note "claude code: removing theme \"custom:omarchy\" from settings.json"
  [ "$DRY" = 1 ] || python3 - "$CLAUDE_DIR/settings.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p))
if d.get("theme") == "custom:omarchy": d.pop("theme")
json.dump(d, open(p, "w"), indent=2); open(p, "a").write("\n")
PY
fi

OBSIDIAN_JSON="$HOME/Library/Application Support/obsidian/obsidian.json"
if [ -f "$OBSIDIAN_JSON" ]; then
  DRY="$DRY" python3 - "$OBSIDIAN_JSON" <<'PY'
import json, os, shutil, sys
dry = os.environ["DRY"] == "1"
for v in json.load(open(sys.argv[1])).get("vaults", {}).values():
    root = os.path.join(v["path"], ".obsidian")
    tdir = os.path.join(root, "themes", "Omarchy")
    ap = os.path.join(root, "appearance.json")
    touched = False
    if os.path.isdir(tdir):
        touched = True
        if not dry: shutil.rmtree(tdir)
    if os.path.exists(ap):
        a = json.load(open(ap))
        if a.get("cssTheme") == "Omarchy":
            touched = True
            if not dry:
                a["cssTheme"] = ""; json.dump(a, open(ap, "w"), indent=2)
    if touched: print(f"    obsidian: reverted vault {v['path']}")
PY
fi

# ---- 4b. Put back the settings the installer snapshotted -------------------
ORIG="$HOME/.local/state/omarchy4mac/originals"
if [ -f "$ORIG/values.json" ]; then
  say "Restoring your pre-omarchy settings from $ORIG"
  DRY="$DRY" ORIG="$ORIG" CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}" python3 - <<'PY'
import json, os, re, shutil
dry = os.environ["DRY"] == "1"; orig = os.environ["ORIG"]
v = json.load(open(os.path.join(orig, "values.json")))
H = os.path.expanduser("~")
def say(m): print("    " + m)
def short(p): return p.replace(H, "~", 1)
# Ghostty: put the original theme line back (omarchy's was dropped above).
for cfg, val in v.get("ghostty", {}).items():
    if not val or val.startswith("omarchy-") or not os.path.isfile(cfg): continue
    text = open(cfg).read()
    if re.search(r"^\s*theme\s*=", text, re.M): continue
    say(f"ghostty: theme = {val} ({short(cfg)})")
    if not dry: open(cfg, "a").write(("" if text.endswith("\n") else "\n") + f"theme = {val}\n")
# btop
b, conf = v.get("btop"), H + "/.config/btop/btop.conf"
if b and "omarchy-" not in b and os.path.isfile(conf):
    say(f"btop: color_theme = {b}")
    if not dry:
        t = re.sub(r"^\s*color_theme\s*=.*$", f"color_theme = {b}", open(conf).read(), flags=re.M)
        open(conf, "w").write(t)
# Neovim: theme.lua was overwritten whole, so the whole file comes back.
nv = H + "/.config/nvim/lua/plugins/theme.lua"
if v.get("nvim_theme_existed") and os.path.isfile(os.path.join(orig, "files") + nv):
    say(f"neovim: restoring your {short(nv)}")
    if not dry:
        os.makedirs(os.path.dirname(nv), exist_ok=True)
        shutil.copy2(os.path.join(orig, "files") + nv, nv)
# Claude Code
ct, cs = v.get("claude_theme"), os.path.join(os.environ["CLAUDE_DIR"], "settings.json")
if ct and ct != "custom:omarchy" and os.path.isfile(cs):
    say(f'claude code: theme = "{ct}"')
    if not dry:
        d = json.load(open(cs)); d["theme"] = ct
        json.dump(d, open(cs, "w"), indent=2); open(cs, "a").write("\n")
# Obsidian
for ap, css in v.get("obsidian", {}).items():
    if css is None or css == "Omarchy" or not os.path.isfile(ap): continue
    say(f'obsidian: cssTheme = "{css}" ({short(os.path.dirname(os.path.dirname(ap)))})')
    if not dry:
        a = json.load(open(ap)); a["cssTheme"] = css; json.dump(a, open(ap, "w"), indent=2)
# Desktop picture
w = v.get("wallpaper")
if w and os.path.isfile(w) and "/Pictures/Wallpapers/" not in w:
    say(f"wallpaper: {short(w)}")
    if not dry:
        os.system(f"osascript -e 'tell application \"System Events\" to set picture of every desktop to \"{w}\"' >/dev/null 2>&1")
PY
  note "full pre-install copies stay in $ORIG/files if you need anything else"
fi

# ---- 5. State files -------------------------------------------------------
say "Removing state"
run rm -rf "$HOME/.local/state/omarchy"
run rm -f "$HOME/.cache/omarchy-wallpaper-index"

if [ "$PURGE" = 1 ]; then
  say "Purging downloaded themes, wallpapers, screensaver, logs"
  # Wallpapers are <theme>_<file>; match against the synced theme names
  # before the cache that lists them goes away. Your unprefixed files stay.
  CACHE="$HOME/.config/theme-switcher/cache"
  if [ -d "$CACHE" ] && [ -d "$HOME/Pictures/Wallpapers" ]; then
    for t in "$CACHE"/*/; do
      t="$(basename "$t")"
      ls "$HOME/Pictures/Wallpapers/${t}_"* >/dev/null 2>&1 && run rm -f "$HOME/Pictures/Wallpapers/${t}_"*
    done
    rmdir "$HOME/Pictures/Wallpapers" 2>/dev/null || true
  fi
  run rm -rf "$HOME/.config/theme-switcher"
  run rm -rf "$HOME/.config/omarchy"
  run rm -rf "$HOME/.local/state/omarchy4mac"
  run rm -f "$HOME/Library/Logs/aerospace-keepalive.log" "$HOME/Library/Logs/theme-appearance.log"
  if command -v cargo >/dev/null 2>&1 && cargo install --list 2>/dev/null | grep -q '^ttfx '; then
    run cargo uninstall ttfx
  fi
  if [ -d "$DIR/.git" ]; then
    say "Deleting clone $DIR"
    run rm -rf "$DIR"
  fi
else
  note "kept: clone ($DIR), ~/.config/theme-switcher, ~/.config/omarchy, ~/Pictures/Wallpapers (use --purge)"
fi

# ---- 6. Packages ----------------------------------------------------------
# Only the pieces that exist for this setup. The general tools are listed,
# not removed: plenty of people use Ghostty, Neovim, fzf etc. on their own.
if [ "$PKGS" = 1 ] && command -v brew >/dev/null 2>&1; then
  say "Uninstalling window-manager packages"
  for c in aerospace hammerspoon; do
    brew list --cask "$c" >/dev/null 2>&1 && run brew uninstall --cask "$c" || true
  done
  for f in sketchybar borders; do
    brew list --formula "$f" >/dev/null 2>&1 && run brew uninstall "$f" || true
  done
  for t in felixkratz/formulae nikitabobko/tap; do
    brew tap | grep -qi "^$t\$" && run brew untap "$t" || true
  done
fi

say "Done."
note "Not reverted automatically: Hermes skins if you use Hermes, Accessibility grants"
note "(System Settings > Privacy & Security), and the desktop picture if no snapshot existed."
[ "$PKGS" = 1 ] || note "WM packages left installed; rerun with --remove-packages to remove them."
note "Shared tools from the Brewfile, remove by hand if unwanted:"
note "  brew uninstall starship btop neovim fastfetch bun eza bat fzf zoxide"
note "  brew uninstall --cask ghostty font-hack-nerd-font brave-browser raycast fluidvoice"
note "Open a new terminal (or exec zsh) so the shell hook is gone."
