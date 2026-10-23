# omarchy4mac dependencies. `install.sh` runs `brew bundle` on this file.

tap "FelixKratz/formulae"   # sketchybar and borders live here, not in core
tap "nikitabobko/tap"       # aerospace is not in homebrew/cask (issue #2)

# Window manager, bar, borders, terminal, prompt, editor, monitor
cask "nikitabobko/tap/aerospace"
cask "ghostty"
cask "hammerspoon"
brew "sketchybar"
brew "borders"
brew "starship"
brew "btop"
brew "neovim"
brew "fastfetch"   # menu > About
brew "bun"         # bar agents widget runs `bunx ccusage`; hidden when there is no usage
brew "media-control"  # bar music item reads macOS Now Playing (any player)
brew "tmux"          # ⌘⌥Return opens Ghostty in the tmux session "Work"

# Shell defaults from Omarchy (zsh/omarchy.zsh)
brew "eza"
brew "bat"
brew "fzf"
brew "zoxide"

# Fonts the bar and terminal expect
cask "font-hack-nerd-font"
cask "font-sketchybar-app-font"   # the app icons in the bar; without it the bar prints :finder:

# Apps the keybindings count on. None are bundled with the config; these are
# the stand-ins the parity table scores. Skip with SKIP_APPS=1.
cask "brave-browser" unless ENV["SKIP_APPS"]
cask "raycast" unless ENV["SKIP_APPS"]
cask "fluidvoice" unless ENV["SKIP_APPS"]
