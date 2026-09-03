# omarchy4mac dependencies. `install.sh` runs `brew bundle` on this file.

# Window manager, bar, borders, terminal, prompt, editor, monitor
cask "aerospace"
cask "ghostty"
cask "hammerspoon"
brew "sketchybar"
brew "borders"
brew "starship"
brew "btop"
brew "neovim"

# Shell defaults from Omarchy (zsh/omarchy.zsh)
brew "eza"
brew "bat"
brew "fzf"
brew "zoxide"

# Fonts the bar and terminal expect
cask "font-hack-nerd-font"

# Apps the keybindings count on. None are bundled with the config; these are
# the stand-ins the parity table scores. Skip with SKIP_APPS=1.
cask "brave-browser" unless ENV["SKIP_APPS"]
cask "raycast" unless ENV["SKIP_APPS"]
cask "fluidvoice" unless ENV["SKIP_APPS"]
