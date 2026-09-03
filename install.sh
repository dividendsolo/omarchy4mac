#!/usr/bin/env bash
# omarchy4mac installer. One command, idempotent: run it again to update.
#
#   curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash
#   ~/code/omarchy4mac/install.sh            # from a clone; also the update command
#   ~/code/omarchy4mac/install.sh --dry-run  # print what would happen, change nothing
#
# What it does, in order: clone or pull the repo, brew bundle, symlink every
# config into place (existing files are moved to *.bak-<date>), compile the
# light/dark listener, load the two launchd agents, source the shell file,
# pull the Omarchy themes, start the services.
#
# Env: SKIP_APPS=1 skips Brave, Raycast, FluidVoice. OMARCHY4MAC_DIR overrides
# the clone location (default ~/code/omarchy4mac).
set -euo pipefail

DIR="${OMARCHY4MAC_DIR:-$HOME/code/omarchy4mac}"
REPO="https://github.com/dividendsolo/omarchy4mac.git"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then echo "    $*"; else "$@"; fi; }

# ---- 0. Xcode CLT and Homebrew -------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools (a dialog will open; rerun after it finishes)"
  run xcode-select --install; exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---- 1. Clone or update ---------------------------------------------------
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR"
  run git -C "$DIR" pull --ff-only
else
  say "Cloning into $DIR"
  run mkdir -p "$(dirname "$DIR")"
  run git clone "$REPO" "$DIR"
fi

# ---- 2. Packages ----------------------------------------------------------
say "brew bundle"
run brew bundle --file="$DIR/Brewfile"

# ---- 3. Symlinks ----------------------------------------------------------
link() {  # link <repo-relative source> <absolute target>
  local src="$DIR/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    say "  backing up $dst -> $dst.bak-$STAMP"
    run mv "$dst" "$dst.bak-$STAMP"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}
say "Linking config"
link aerospace/aerospace.toml   "$HOME/.aerospace.toml"
link sketchybar                 "$HOME/.config/sketchybar"
link borders                    "$HOME/.config/borders"
link starship/starship.toml     "$HOME/.config/starship.toml"
link hammerspoon/init.lua       "$HOME/.hammerspoon/init.lua"
for f in "$DIR"/bin/*; do
  name="${f##*/}"
  case "$name" in *.swift) continue ;; esac
  link "bin/$name" "$HOME/.local/bin/$name"
done
run mkdir -p "$HOME/.config/omarchy/branding"
[ -e "$HOME/.config/omarchy/branding/screensaver.txt" ] || run cp "$DIR/omarchy/screensaver.txt" "$HOME/.config/omarchy/branding/screensaver.txt"

# ---- 4. Shell -------------------------------------------------------------
LINE="source \"$DIR/zsh/omarchy.zsh\""
if ! grep -qsF "$LINE" "$HOME/.zshrc"; then
  say "Adding omarchy.zsh to ~/.zshrc"
  [ "$DRY" = 1 ] || printf '\n# omarchy4mac shell defaults\n%s\n' "$LINE" >> "$HOME/.zshrc"
fi

# ---- 5. Light/dark listener + launchd agents ------------------------------
if command -v swiftc >/dev/null 2>&1; then
  say "Compiling the light/dark listener"
  run swiftc -O -o "$HOME/.local/bin/theme-appearance-listener" "$DIR/bin/theme-appearance-listener.swift"
else
  say "swiftc not found; skipping the light/dark listener"
fi
say "Loading launchd agents"
run mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
for p in "$DIR"/launchd/*.plist; do
  name="${p##*/}"; dst="$HOME/Library/LaunchAgents/$name"
  if [ "$DRY" = 1 ]; then echo "    render $p -> $dst; launchctl load"; continue; fi
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
fi

# ---- 8. Services ----------------------------------------------------------
say "Starting services"
run brew services restart sketchybar
run brew services restart borders
run open -a Hammerspoon
[ "$DRY" = 1 ] || { pgrep -x AeroSpace >/dev/null && aerospace reload-config || open -a AeroSpace; }

say "Done. Grant Accessibility to Hammerspoon and AeroSpace when macOS asks."
say "⌥K shows every keybinding. ⌘⌥Space opens the menu. Rerun this script to update."
