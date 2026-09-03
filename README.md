# omarchy-mac

An [Omarchy](https://github.com/basecamp/omarchy) port for macOS — for those of
us who want the Omarchy experience but can't (or won't) leave the Mac.

Omarchy is DHH's opinionated Arch + Hyprland setup. This repo recreates the
parts that matter on macOS with native tools:

| Omarchy piece | macOS stand-in | Config here |
|---|---|---|
| Hyprland (tiling WM) | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | `aerospace/` |
| Waybar | [SketchyBar](https://github.com/FelixKratz/SketchyBar) | `sketchybar/` |
| Window borders | [JankyBorders](https://github.com/FelixKratz/JankyBorders) | `borders/` |
| Keybindings / menus | [Hammerspoon](https://www.hammerspoon.org) | `hammerspoon/` |
| Omarchy themes | `theme` script (syncs from basecamp/omarchy) | `bin/theme` |
| Prompt | [Starship](https://starship.rs) | `starship/` |

The `theme` script is the centerpiece: `theme --sync` pulls every theme
straight from the Omarchy repo and converts it for Ghostty, Neovim (LazyVim),
and btop. `theme random` respects macOS light/dark appearance, and a launchd
listener re-themes everything the instant the system flips appearance.

## Prerequisites

```sh
brew install --cask aerospace ghostty hammerspoon
brew install sketchybar borders starship btop neovim
brew install eza bat fzf zoxide        # for zsh/omarchy.zsh (optional)
cargo install --git https://github.com/omacom/ttfx   # screensaver (optional)
```

Neovim theming assumes [LazyVim](https://www.lazyvim.org) (themes are written
to `~/.config/nvim/lua/plugins/theme.lua`).

## Install

Clone, then symlink what you want:

```sh
git clone https://github.com/dividendsolo/omarchy-mac.git ~/code/omarchy-mac
D=~/code/omarchy-mac

# Window manager / bar / borders
ln -s "$D/aerospace/aerospace.toml" ~/.aerospace.toml
ln -s "$D/sketchybar" ~/.config/sketchybar
ln -s "$D/borders" ~/.config/borders

# Prompt
ln -s "$D/starship/starship.toml" ~/.config/starship.toml

# Hammerspoon (keybindings overlay, Omarchy menu, theme chooser)
mkdir -p ~/.hammerspoon
ln -s "$D/hammerspoon/init.lua" ~/.hammerspoon/init.lua

# Scripts
mkdir -p ~/.local/bin
for f in theme omarchy-system-menu omarchy-cycle-wallpaper omarchy-notice theme-appearance-watch \
         omarchy-tui omarchy-agent omarchy-launch-screensaver omarchy-screensaver omarchy-toggle-screensaver gaming-mode; do
  ln -s "$D/bin/$f" ~/.local/bin/$f
done
ln -s ~/.cargo/bin/ttfx ~/.local/bin/ttfx   # if you installed the screensaver
mkdir -p ~/.config/omarchy/branding && cp "$D/omarchy/screensaver.txt" ~/.config/omarchy/branding/

# Shell aliases (optional)
echo 'source ~/code/omarchy-mac/zsh/omarchy.zsh' >> ~/.zshrc

# Pull the Omarchy themes
theme --sync
theme tokyo-night
```

Then start the services:

```sh
brew services start sketchybar
brew services start borders
open -a Hammerspoon    # grant Accessibility when asked
```

### Auto-theming on light/dark flip (optional)

A tiny resident Swift listener reacts to `AppleInterfaceThemeChangedNotification`
and switches to a random theme matching the new appearance:

```sh
swiftc -O -o ~/.local/bin/theme-appearance-listener bin/theme-appearance-listener.swift
sed "s|/Users/YOU|$HOME|g" launchd/com.omarchy-mac.theme-appearance.plist \
  > ~/Library/LaunchAgents/com.omarchy-mac.theme-appearance.plist
launchctl load ~/Library/LaunchAgents/com.omarchy-mac.theme-appearance.plist
```

### AeroSpace crash watchdog (optional, recommended on macOS 26)

AeroSpace can self-terminate on macOS Tahoe. This launchd agent starts it at
login and relaunches it only on a crash (a clean quit is respected):

```sh
sed "s|/Users/YOU|$HOME|g" launchd/com.omarchy-mac.aerospace-keepalive.plist \
  > ~/Library/LaunchAgents/com.omarchy-mac.aerospace-keepalive.plist
launchctl load ~/Library/LaunchAgents/com.omarchy-mac.aerospace-keepalive.plist
```

Disable AeroSpace's own "start at login" if you use this.

## Wallpapers

`omarchy-cycle-wallpaper` (⌘⌃P) cycles images in `~/Pictures/Wallpapers`.
Name files `<theme>_*.jpg` to scope them to a theme (e.g. `tokyo-night_1.jpg`);
unprefixed files act as a shared pool. Wallpapers are not bundled — bring your
own or grab Omarchy's from the [omarchy repo](https://github.com/basecamp/omarchy).

## Keybindings

Press **⌥K** for the searchable overlay. Highlights:

- **⌘⌥Space** — Omarchy system menu (nested, searchable); **⌘Esc** — System submenu
- **⌘⌃⇧Space** — theme chooser
- **⌘⇧ + letter** — web apps as app windows (mail, calendar, chat, photos, YouTube, X)
- **⌘⇧⌃A** — coding agent in a fresh terminal
- **⌘⌃P** — cycle wallpaper
- **⌘⌃I** — keep awake (caffeinate) with a bar indicator
- **⌘⌃G** — gaming mode
- **⌘⌃⌥ T/W/B** — time / weather / battery notice
- **⌥T** — shuffle theme (random theme in the current light/dark mode)
- **⌥S** — float / tile the focused window

## How close is this to real Omarchy?

Honest answer, measured against **Omarchy v4.0.2 (Quattro)**: roughly **half**
of what a v4 user touches in a day is here, and the ceiling on macOS is about
three quarters. The keybinding vocabulary, the workspace model, the menu tree,
the bar layout, and the theme pipeline are ported. The v4 shell (panels,
notifications, lock screen, OSD) is one Quickshell process on Wayland
layer-shell and has no macOS equivalent. Neither do Hyprland groups,
scratchpad, pin, or per-window opacity. The full checklist, item by item, is
in [`docs/parity-v4.md`](docs/parity-v4.md); what changed and when is in
[`CHANGELOG.md`](CHANGELOG.md).

| Area | Status |
|---|---|
| Tiling WM + workspaces | ✅ AeroSpace stands in for Hyprland |
| Top bar, v4 layout (indicators, weather, updates, agents) | ✅ SketchyBar stands in for Waybar |
| Window borders | ✅ JankyBorders |
| Themes, rendered from Omarchy's own v4 templates | ✅ Synced live from the Omarchy repo, all of them; reaches Ghostty, Neovim, btop, Claude Code, Obsidian |
| Auto light/dark theme switching | ✅ Instant, via a native listener (not in Omarchy itself) |
| Wallpaper cycling per theme | ✅ |
| Menu tree (Apps / Learn / Trigger / Style / Setup / Install / Update / System) | ✅ Hammerspoon, nested search |
| Keybinding overlay | ✅ every binding listed |
| Web apps as app windows | ✅ Brave app windows on the v4 keys |
| Screensaver | ✅ ttfx ASCII art after 150 s idle |
| Shell defaults (eza, bat, fzf, zoxide, aliases) | ✅ `zsh/omarchy.zsh` |
| Utility keys (emoji, clipboard, caffeinate, lock, agent) | ✅ |
| Weather / battery / time notices | ✅ |
| App launcher | ⚠️ Use Raycast or Spotlight; no walker port |
| Night light, bar toggle, gap toggle | ❌ No macOS or AeroSpace hook |
| Panels, OSD, lock screen, groups, scratchpad, pin, opacity | ❌ Not portable |
| Screenshots / screen recording / OCR capture | ❌ macOS has its own (⌘⇧5) |
| Installer, updates, migrations, hardware, Plymouth | ❌ Not applicable on macOS |

If a gap bothers you, open an issue.

## Credits

- [basecamp/omarchy](https://github.com/basecamp/omarchy) — the original, and
  the live source of every theme this port uses.
- AeroSpace, SketchyBar, JankyBorders, Hammerspoon, Starship — the projects
  doing the actual work.

## License

MIT
