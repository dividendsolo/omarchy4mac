#!/usr/bin/env bash
# omarchy4mac installer. One command, idempotent: run it again to update.
#
#   curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash
#   ~/code/omarchy4mac/install.sh            # from a clone; also the update command
#   ~/code/omarchy4mac/install.sh --dry-run  # print what would happen, change nothing
#   curl -fsSL …/install.sh | bash -s -- --dry-run   # same, before you have a clone
#
# The dry run reads your system and reports what the real run would do: which
# brew packages it would install or upgrade, apps already in /Applications that
# would block a cask install, every file it would back up or link, the lines it
# would add to ~/.zshrc, and the settings `theme` would rewrite in other apps.
# It writes nothing outside a temporary preview clone, deleted on exit.
#
# What it does, in order: clone or pull the repo, brew bundle, symlink every
# config into place (existing files are moved to *.bak-<date>), compile the
# light/dark listener, load the two launchd agents, source the shell file,
# pull the Omarchy themes, start the services.
#
# Before touching anything, the first run snapshots every setting the `theme`
# script rewrites in other apps (Ghostty, btop, Neovim, Claude Code, Obsidian,
# the desktop picture) plus ~/.zshrc, into ~/.local/state/omarchy4mac/originals.
# Later runs leave that snapshot alone, so it always holds your pre-omarchy
# setup. uninstall.sh puts those values back.
#
# Env: SKIP_APPS=1 skips Brave, Raycast, FluidVoice. OMARCHY4MAC_DIR overrides
# the clone location (default ~/code/omarchy4mac).
set -euo pipefail
TILDE="~"   # for ${path/#$HOME/$TILDE}; a bare ~ there expands back to $HOME in bash 5.2

DIR="${OMARCHY4MAC_DIR:-$HOME/code/omarchy4mac}"
REPO="https://github.com/dividendsolo/omarchy4mac.git"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
STAMP="$(date +%Y%m%d-%H%M%S)"
ORIG="$HOME/.local/state/omarchy4mac/originals"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; WARNINGS=$((WARNINGS+1)); }
run()  { if [ "$DRY" = 1 ]; then echo "    would: $*"; else "$@"; fi; }
WARNINGS=0
SRC="$DIR"   # where repo files are read from; a temp clone during a dry run with no clone yet
if [ "$DRY" = 1 ]; then
  printf '\033[1;33m==> DRY RUN: reporting only, nothing on this Mac will change\033[0m\n'
fi

# ---- 0. Xcode CLT and Homebrew -------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools (a dialog will open; rerun after it finishes)"
  run xcode-select --install; exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew"
  if [ "$DRY" = 1 ]; then
    echo "    would: run the Homebrew installer, then install every package in the Brewfile"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# ---- 0b. Snapshot the settings `theme` will rewrite ------------------------
# Full copies go in $ORIG/files/<absolute path> as a safety net; the specific
# values (Ghostty theme line, btop color_theme, Claude "theme", Obsidian
# cssTheme, desktop picture) go in $ORIG/values.json so uninstall.sh can put
# back just those settings without clobbering edits made since.
snapshot() {
  if [ -f "$ORIG/values.json" ]; then
    say "Originals already saved ($ORIG); keeping them"
    return
  fi
  if [ -f "$HOME/.config/theme-switcher/current" ]; then
    say "WARNING: omarchy4mac was installed before this snapshot existed;"
    say "         the snapshot records today's settings, not your pre-omarchy ones."
  fi
  say "Saving your current settings to $ORIG"
  if [ "$DRY" = 1 ]; then
    local f any=0
    for f in "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
             "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config" \
             "$HOME/.config/btop/btop.conf" \
             "$HOME/.config/nvim/lua/plugins/theme.lua" \
             "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
             "$HOME/.zshrc"; do
      [ -f "$f" ] && { echo "    would save: ${f/#$HOME/$TILDE}"; any=1; }
    done
    [ -f "$HOME/Library/Application Support/obsidian/obsidian.json" ] && echo "    would save: each Obsidian vault's appearance.json"
    echo "    would save: the current desktop picture path"
    [ "$any" = 1 ] || echo "    (none of the app configs exist yet)"
    return
  fi
  mkdir -p "$ORIG"
  local pic
  pic="$(osascript -e 'tell application "System Events" to tell current desktop to get picture' 2>/dev/null || true)"
  ORIG="$ORIG" PIC="$pic" CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}" \
  XDG="${XDG_CONFIG_HOME:-$HOME/.config}" python3 - <<'PY'
import json, os, re, shutil
H = os.path.expanduser("~"); orig = os.environ["ORIG"]
def save(p):
    if os.path.isfile(p):
        dst = os.path.join(orig, "files") + p
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(p, dst)
        return True
    return False
def first(p, rx):
    if not os.path.isfile(p): return None
    for line in open(p, errors="replace"):
        m = re.match(rx, line)
        if m: return m.group(1).strip()
    return None
v = {"saved_at": __import__("time").strftime("%Y-%m-%d %H:%M:%S"), "ghostty": {}, "obsidian": {}}
for cfg in (H + "/Library/Application Support/com.mitchellh.ghostty/config",
            os.environ["XDG"] + "/ghostty/config"):
    if save(cfg): v["ghostty"][cfg] = first(cfg, r"^\s*theme\s*=(.*)$")
btop = H + "/.config/btop/btop.conf"
v["btop"] = first(btop, r"^\s*color_theme\s*=(.*)$") if save(btop) else None
nvim = H + "/.config/nvim/lua/plugins/theme.lua"
v["nvim_theme_existed"] = save(nvim)
cs = os.path.join(os.environ["CLAUDE_DIR"], "settings.json")
v["claude_theme"] = None
if save(cs):
    try: v["claude_theme"] = json.load(open(cs)).get("theme")
    except Exception: pass
save(H + "/.zshrc")
obs = H + "/Library/Application Support/obsidian/obsidian.json"
if os.path.isfile(obs):
    try: vaults = json.load(open(obs)).get("vaults", {}).values()
    except Exception: vaults = []
    for vt in vaults:
        ap = os.path.join(vt["path"], ".obsidian", "appearance.json")
        css = None
        if save(ap):
            try: css = json.load(open(ap)).get("cssTheme")
            except Exception: pass
        v["obsidian"][ap] = css
v["wallpaper"] = os.environ.get("PIC") or None
json.dump(v, open(os.path.join(orig, "values.json"), "w"), indent=2)
PY
}
snapshot

# ---- 1. Clone or update ---------------------------------------------------
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR"
  if [ "$DRY" = 1 ]; then
    remote="$(git -C "$DIR" remote get-url origin 2>/dev/null || echo none)"
    case "$remote" in
      *dividendsolo/omarchy4mac*) ;;
      *) warn "$DIR is a git repo for '$remote', not omarchy4mac; the real run would pull it anyway" ;;
    esac
    [ -z "$(git -C "$DIR" status --porcelain 2>/dev/null)" ] \
      || warn "$DIR has uncommitted changes; 'git pull --ff-only' may refuse and stop the install"
  fi
  run git -C "$DIR" pull --ff-only
else
  if [ -e "$DIR" ]; then
    warn "$DIR exists but is not a git clone; the real run's 'git clone' will fail and stop"
  fi
  say "Cloning into $DIR"
  run mkdir -p "$(dirname "$DIR")"
  run git clone "$REPO" "$DIR"
  if [ "$DRY" = 1 ]; then
    # Read the repo's file list and Brewfile from a throwaway clone.
    SRC="$(mktemp -d)/omarchy4mac"
    trap 'rm -rf "$(dirname "$SRC")"' EXIT
    git clone -q --depth 1 "$REPO" "$SRC" 2>/dev/null \
      || { warn "could not fetch $REPO for the preview; stopping"; exit 1; }
  fi
fi

# ---- 2. Packages ----------------------------------------------------------
say "brew bundle"
if [ "$DRY" = 1 ]; then
  if command -v brew >/dev/null 2>&1; then
    if check="$(brew bundle check --verbose --no-upgrade --file="$SRC/Brewfile" 2>&1)"; then
      check=""
    fi
    if [ -n "$check" ]; then
      echo "    would install:"
      printf '%s\n' "$check" | grep 'needs to be' | sed 's/^[^A-Za-z]*/      /' \
        || printf '%s\n' "$check" | sed 's/^/      /'
    else
      echo "    everything in the Brewfile is already installed"
    fi
    wanted="$( { brew bundle list --formula --file="$SRC/Brewfile"; brew bundle list --cask --file="$SRC/Brewfile"; } 2>/dev/null | sed 's|.*/||' | sort -u)"
    outdated="$(brew outdated --quiet 2>/dev/null | sed 's|.*/||' | sort -u)"
    up="$(comm -12 <(printf '%s\n' "$wanted") <(printf '%s\n' "$outdated") | tr '\n' ' ')"
    [ -n "${up// /}" ] && echo "    would upgrade (brew bundle upgrades outdated entries): $up"
    # Casks whose app is already in /Applications without Homebrew: the
    # install refuses to overwrite them and the script stops there.
    casks="$(brew bundle list --cask --file="$SRC/Brewfile" 2>/dev/null || true)"
    have="$(brew list --cask 2>/dev/null | sed 's|.*/||' || true)"
    for c in $casks; do
      short="${c##*/}"
      printf '%s\n' "$have" | grep -qx "$short" && continue
      case "$c" in */*/*) brew tap | grep -qix "${c%/*}" || { echo "    (can't check $short until its tap is added)"; continue; } ;; esac
      while IFS= read -r line; do warn "$line; brew will refuse it and the install will stop"; done < <(
      brew info --cask --json=v2 "$c" 2>/dev/null | python3 -c '
import json, os, sys
try: cask = json.load(sys.stdin)["casks"][0]
except Exception: sys.exit()
H = os.path.expanduser("~")
tok = cask.get("token", "?")
for a in cask.get("artifacts", []):
    if not isinstance(a, dict): continue
    for app in a.get("app", []):
        if isinstance(app, str) and any(os.path.exists(d + "/" + app) for d in ("/Applications", H + "/Applications")):
            print(tok + ": " + app + " is already installed outside Homebrew")
    for font in a.get("font", []):
        if isinstance(font, str) and os.path.exists(H + "/Library/Fonts/" + os.path.basename(font)):
            print(tok + ": " + os.path.basename(font) + " is already in ~/Library/Fonts")
' 2>/dev/null || true)
    done
  else
    echo "    would install everything in the Brewfile:"
    grep -E '^(brew|cask|tap) ' "$SRC/Brewfile" | sed 's/[[:space:]]*#.*//; s/^/      /'
  fi
else
  brew bundle --file="$DIR/Brewfile"
fi

# ---- 3. Symlinks ----------------------------------------------------------
link() {  # link <repo-relative source> <absolute target>
  local src="$DIR/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    [ "$DRY" = 1 ] && echo "    ok: ${dst/#$HOME/$TILDE} already linked"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    say "  backing up $dst -> $dst.bak-$STAMP"
    run mv "$dst" "$dst.bak-$STAMP"
  fi
  [ "$DRY" = 1 ] || mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}
say "Linking config"
link aerospace/aerospace.toml   "$HOME/.aerospace.toml"
link sketchybar                 "$HOME/.config/sketchybar"
link borders                    "$HOME/.config/borders"
link starship/starship.toml     "$HOME/.config/starship.toml"
link hammerspoon/init.lua       "$HOME/.hammerspoon/init.lua"
for f in "$SRC"/bin/*; do
  name="${f##*/}"
  case "$name" in *.swift) continue ;; esac
  link "bin/$name" "$HOME/.local/bin/$name"
done
run mkdir -p "$HOME/.config/omarchy/branding"
[ -e "$HOME/.config/omarchy/branding/screensaver.txt" ] && { [ "$DRY" = 0 ] || echo "    ok: screensaver.txt exists, kept"; } || run cp "$DIR/omarchy/screensaver.txt" "$HOME/.config/omarchy/branding/screensaver.txt"

# ---- 4. Shell -------------------------------------------------------------
LINE="source \"$DIR/zsh/omarchy.zsh\""
if ! grep -qsF "$LINE" "$HOME/.zshrc"; then
  say "Adding omarchy.zsh to ~/.zshrc (backup: ~/.zshrc.bak-$STAMP)"
  [ "$DRY" = 1 ] || [ ! -f "$HOME/.zshrc" ] || cp -p "$HOME/.zshrc" "$HOME/.zshrc.bak-$STAMP"
  [ "$DRY" = 1 ] || printf '\n# omarchy4mac shell defaults\n%s\n' "$LINE" >> "$HOME/.zshrc"
  if [ "$DRY" = 1 ]; then
    echo "    would append: $LINE"
    clash="$(grep -oE "^alias (ls|cd|g|d|r|t|h|n|ff|lt)=" "$HOME/.zshrc" 2>/dev/null | sed 's/^alias //; s/=$//' | tr '\n' ' ' || true)"
    [ -n "$clash" ] && warn "omarchy.zsh loads last and replaces your aliases: $clash"
  fi
fi

# ---- 5. Light/dark listener + launchd agents ------------------------------
LISTENER=0
if command -v swiftc >/dev/null 2>&1; then
  say "Compiling the light/dark listener"
  run swiftc -O -o "$HOME/.local/bin/theme-appearance-listener" "$DIR/bin/theme-appearance-listener.swift" && LISTENER=1
else
  say "swiftc not found; skipping the light/dark listener and its launchd agent"
fi
say "Loading launchd agents"
run mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
for p in "$SRC"/launchd/*.plist; do
  name="${p##*/}"; dst="$HOME/Library/LaunchAgents/$name"
  case "$name" in *theme-appearance*) [ "$LISTENER" = 1 ] || continue ;; esac
  if [ "$DRY" = 1 ]; then echo "    would: install ${dst/#$HOME/$TILDE} and launchctl load it"; continue; fi
  sed "s|/Users/YOU|$HOME|g" "$p" > "$dst"
  launchctl unload "$dst" 2>/dev/null || true
  launchctl load "$dst"
done

# ---- 6. Screensaver (optional, needs cargo) -------------------------------
if command -v cargo >/dev/null 2>&1 && ! command -v ttfx >/dev/null 2>&1; then
  say "Building ttfx for the screensaver"
  run cargo install --git https://github.com/omacom/ttfx
  run ln -sf "$HOME/.cargo/bin/ttfx" "$HOME/.local/bin/ttfx"
elif ! command -v ttfx >/dev/null 2>&1; then
  say "cargo not found; screensaver skipped (install rustup, rerun)"
fi

# ---- 7. Themes ------------------------------------------------------------
say "Syncing Omarchy themes"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
run theme --sync
if [ ! -f "$HOME/.config/theme-switcher/current" ]; then
  say "First theme: tokyo-night"
  run theme tokyo-night
  if [ "$DRY" = 1 ]; then
    echo "    applying it would change (originals are in the snapshot above):"
    for cfg in "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"; do
      [ -f "$cfg" ] || continue
      cur="$(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n1 || true)"
      echo "      Ghostty  ${cfg/#$HOME/$TILDE}: theme ${cur:-<default>} -> omarchy-tokyo-night"
    done
    b="$(sed -n 's/^[[:space:]]*color_theme[[:space:]]*=[[:space:]]*//p' "$HOME/.config/btop/btop.conf" 2>/dev/null | head -n1 || true)"
    echo "      btop     color_theme ${b:-<default>} -> \"omarchy-tokyo-night\""
    nv="$HOME/.config/nvim/lua/plugins/theme.lua"
    if [ -f "$nv" ] && ! head -n1 "$nv" | grep -q 'generated by `theme'; then
      warn "Neovim   ~/.config/nvim/lua/plugins/theme.lua is yours and would be replaced outright"
    else
      echo "      Neovim   writes ~/.config/nvim/lua/plugins/theme.lua"
    fi
    cdir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    if [ -d "$cdir" ]; then
      ct="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("theme") or "<default>")' "$cdir/settings.json" 2>/dev/null || echo "<default>")"
      echo "      Claude   theme $ct -> custom:omarchy"
    fi
    obs="$HOME/Library/Application Support/obsidian/obsidian.json"
    if [ -f "$obs" ]; then
      n="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1])).get("vaults",{})))' "$obs" 2>/dev/null || echo "?")"
      echo "      Obsidian cssTheme -> Omarchy in $n vault(s)"
    fi
    echo "      Desktop  picture -> a tokyo-night wallpaper"
  fi
else
  [ "$DRY" = 1 ] && echo "    current theme $(cat "$HOME/.config/theme-switcher/current") stays"
fi

# ---- 8. Services ----------------------------------------------------------
say "Starting services"
run brew services restart sketchybar
run brew services restart borders
run open -a Hammerspoon
if [ "$DRY" = 1 ]; then
  echo "    would: reload AeroSpace if it is running, otherwise launch it"
else
  pgrep -x AeroSpace >/dev/null && aerospace reload-config || open -a AeroSpace
fi

if [ "$DRY" = 1 ]; then
  if [ "$WARNINGS" -gt 0 ]; then
    printf '\033[1;33m==> Dry run finished with %s warning(s) above. Nothing was changed.\033[0m\n' "$WARNINGS"
  else
    printf '\033[1;32m==> Dry run finished, no problems found. Nothing was changed.\033[0m\n'
  fi
  exit 0
fi

say "Done. Grant Accessibility to Hammerspoon and AeroSpace when macOS asks."
say "⌥K shows every keybinding. ⌘⌥Space opens the menu. Rerun this script to update."
say "Your previous Ghostty/btop/Neovim/Claude/Obsidian settings are saved in $ORIG."
