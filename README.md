# omarchy4mac

Omarchy 4, for the Mac. An [Omarchy](https://github.com/basecamp/omarchy) port for macOS — for those of
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

## Install

One command. It installs Homebrew if needed, runs the `Brewfile`, links every
config into place (anything already there is moved to `*.bak-<date>`), compiles
the light/dark listener, loads the launchd agents, adds the shell file to
`~/.zshrc`, pulls the Omarchy themes, and starts the services:

```sh
curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash
```

Grant Accessibility to Hammerspoon and AeroSpace when macOS asks. Then ⌥K for
the keybindings, ⌘⌥Space for the menu.

**Update:** run the same script again. It pulls, relinks, resyncs themes, and
restarts the services. `~/code/omarchy4mac/install.sh --dry-run` prints what
it would do without touching anything.

**Options:** `SKIP_APPS=1` skips Brave, Raycast, and FluidVoice. Not in the
Brewfile, install what you use: Steam (gaming mode), Claude Code and Obsidian
(the theme reaches them), Signal, 1Password, Typora, LocalSend, HandBrake.
Each has a key; the key does nothing until the app exists.
`OMARCHY4MAC_DIR=/path` changes the clone location. The screensaver needs
`cargo` (rustup); without it the script skips ttfx and says so.

<details>
<summary>By hand, if you would rather see every step</summary>

```sh
brew bundle --file=Brewfile          # or pick from it
git clone https://github.com/dividendsolo/omarchy4mac.git ~/code/omarchy4mac
D=~/code/omarchy4mac

ln -s "$D/aerospace/aerospace.toml" ~/.aerospace.toml
ln -s "$D/sketchybar" ~/.config/sketchybar
ln -s "$D/borders" ~/.config/borders
ln -s "$D/starship/starship.toml" ~/.config/starship.toml
mkdir -p ~/.hammerspoon && ln -s "$D/hammerspoon/init.lua" ~/.hammerspoon/init.lua
mkdir -p ~/.local/bin && for f in "$D"/bin/*; do [[ $f == *.swift ]] || ln -s "$f" ~/.local/bin/; done
mkdir -p ~/.config/omarchy/branding && cp "$D/omarchy/screensaver.txt" ~/.config/omarchy/branding/
echo "source $D/zsh/omarchy.zsh" >> ~/.zshrc

# Light/dark listener + AeroSpace crash watchdog (macOS 26 can kill AeroSpace)
swiftc -O -o ~/.local/bin/theme-appearance-listener "$D/bin/theme-appearance-listener.swift"
for p in "$D"/launchd/*.plist; do
  sed "s|/Users/YOU|$HOME|g" "$p" > ~/Library/LaunchAgents/"${p##*/}"
  launchctl load ~/Library/LaunchAgents/"${p##*/}"
done

# Screensaver (optional)
cargo install --git https://github.com/omacom/ttfx && ln -s ~/.cargo/bin/ttfx ~/.local/bin/ttfx

theme --sync && theme tokyo-night
brew services start sketchybar && brew services start borders && open -a Hammerspoon
```

Neovim theming assumes [LazyVim](https://www.lazyvim.org). Disable AeroSpace's
own "start at login" if you use the watchdog.
</details>

## Wallpapers

`theme --sync` downloads every theme's own backgrounds from the Omarchy repo
into `~/Pictures/Wallpapers` as `<theme>_<file>`. `omarchy-cycle-wallpaper`
(⌘⌃P) cycles the ones for the current theme; unprefixed files you add act as
a shared pool.

## Keybindings

Press **⌥K** for the searchable overlay. Highlights:

- **⌘⌥Space** — Omarchy system menu (nested, searchable); **⌘Esc** — System submenu
- **⌘⌃⇧Space** — theme chooser
- **⌘⇧ + letter** — web apps as app windows (HEY mail and calendar, Google Photos, YouTube, Grok; Google Chat on ⌘⇧⌃G)
- **⌘⇧⌃A** — coding agent in a fresh terminal
- **⌘⌃P** — cycle wallpaper
- **⌘⌃I** — keep awake (caffeinate) with a bar indicator
- **⌘⌃G** — gaming mode
- **⌘⌃⌥ T/W/B** — time / weather / battery notice
- **⌥T** — shuffle theme (random theme in the current light/dark mode)
- **⌥S** — float / tile the focused window

## Bonus features

A few pieces of this port go past parity. They exist because macOS made them
easy, or because a Mac needed them.

- **Auto re-theme on light/dark flip.** Switch macOS appearance and the whole
  desktop switches to a random theme from the matching bucket: light system,
  light theme; dark system, dark theme. Terminal, editor, bar, btop,
  Claude Code, Obsidian, all at once. It is the optional listener above; set
  it up once and forget it. Omarchy has no equivalent, since Hyprland has no
  system appearance to follow.
- **⌥T shuffles within the bucket.** Random theme, never the current one,
  never a dark theme on a light system.
- **Theme reaches Claude Code and Obsidian.** Omarchy stops at the terminal
  and editor. Here a switch recolors the Claude Code terminal theme and the
  Obsidian vault theme too.
- **Crash watchdog.** AeroSpace can self-terminate on macOS 26. The launchd
  agent above relaunches it on a crash and respects a clean quit.
- **Gaming mode (⌘⌃G).** Quits every Dock app, drops Tailscale if it is
  installed, and launches Steam. The reverse is a normal quit.

## How close is this to real Omarchy?

**71%** of Omarchy v4.0.2 (Quattro), scored feature by feature below: ✅ we
have it, or the Mac stand-in does the same job (1 point). ⚠️ partly there,
with a plan (half). ❌ missing, nothing planned, whatever the reason (0).
Items with no macOS meaning are left out. That is 23 matched, 4 partial, 8
not portable, out of 35 scored.

The short version: the keybinding vocabulary, the workspace model, the menu
tree, the bar, the theme pipeline, the screensaver, and the shell are here.
What is not here is Omarchy's Quickshell layer (panels, themed lock screen,
OSD) and the Hyprland dispatchers AeroSpace lacks (groups, scratchpad, pin,
opacity, gap toggle). Those have no macOS equivalent and are not coming.
The item-by-item checklist is in [`docs/parity-v4.md`](docs/parity-v4.md);
what changed and when is in [`CHANGELOG.md`](CHANGELOG.md).

| Omarchy Quattro has | omarchy4mac uses | Match | Why not, and the plan |
|---|---|---|---|
| Tiling WM: focus, move, swap, resize, fullscreen, 5 workspaces, monitors | AeroSpace | ✅ |  |
| Top bar: logo opens menu, workspaces, indicators, clock, weather, updates badge, agents spend, bluetooth, wifi, audio, battery | SketchyBar, v4 layout | ✅ |  |
| Active-window borders | JankyBorders | ✅ |  |
| All 22 v4 themes, generated from Omarchy's own templates | `theme --sync`, renders Ghostty, Neovim, btop from the v4 `.tpl` files | ✅ |  |
| Theme chooser (Super+Ctrl+Shift+Space) | Hammerspoon chooser on ⌘⌃⇧Space | ✅ |  |
| Menu tree: Apps, Learn, Trigger, Style, Setup, Install, Update, System, nested search | Hammerspoon on ⌘⌥Space, ⌘Esc to System | ✅ |  |
| Keybinding overlay (Super+K) | ⌥K, every binding listed | ✅ |  |
| Web apps as app windows (Super+Shift+letter) | Brave `--app=` windows on the same keys (HEY, Photos, YouTube, Grok, Google Chat) | ✅ |  |
| Screensaver: ttfx ASCII art per monitor after 150 s | Hammerspoon idle timer, Ghostty + ttfx per display | ✅ |  |
| Shell defaults: eza, bat, fzf, zoxide, git and tool aliases | `zsh/omarchy.zsh` | ✅ |  |
| Wallpaper per theme, cycle key | `omarchy-cycle-wallpaper` on ⌘⌃P | ✅ |  |
| Emoji picker key | Raycast emoji on ⌘⌃E | ✅ |  |
| Clipboard history key | Raycast clipboard on ⌘⌃V | ✅ |  |
| Idle inhibit (keep awake) with bar indicator | caffeinate on ⌘⌃I, bar indicator | ✅ |  |
| Coding agent in a fresh terminal (Super+Shift+Ctrl+A) | ⌘⇧⌃A, Ghostty + claude | ✅ |  |
| Lock key | macOS lock on ⌘⌃L | ✅ |  |
| Time / weather / battery notices | `omarchy-notice` on ⌘⌃⌥ T/W/B | ✅ |  |
| Screenshots, screen recording | macOS ⌘⇧5 | ✅ | Matched by the OS, not by this repo. |
| Notifications (mako) | macOS Notification Center | ✅ | Matched by the OS. |
| App launcher (walker) | Raycast (free plan) on ⌘Space | ✅ | Works the same for launching. No walker port needed. |
| Voice typing (voxtype) | [FluidVoice](https://fluidvoice.app) | ✅ | Free, open source, Whisper on-device. Not bundled; install it yourself. |
| Install in one command, update in one command | `install.sh`, rerun to update | ✅ |  |
| Theme backgrounds downloaded with the theme | `theme --sync` pulls each theme's `backgrounds/` into `~/Pictures/Wallpapers` | ✅ |  |
| Theme reaches tmux, lazygit, VS Code | Terminal, editor, btop, Claude Code, Obsidian | ⚠️ | Planned when tmux is daily: render v4's tmux template and reload live sessions. lazygit and VS Code only if asked. |
| Night light toggle | None | ⚠️ | Planned: Night Shift via osascript on ⌘⌃N and a menu item. Small. |
| OCR capture-text (Super+Ctrl+Print) | macOS Live Text, by hand | ⚠️ | Planned: region screenshot, Vision text extraction, clipboard, one script. |
| Bar hide/show key | None | ⚠️ | Planned: `sketchybar --bar hidden=toggle` on ⌘⇧Space. One line. |
| Theme colors on the volume / brightness indicator (the box when you press a volume key) | Apple's, unthemed | ❌ | The theme cannot reach it. Apple owns it. |
| Control panels: audio, bluetooth, network, display, power, calendar (Quickshell) | System Settings deep links | ❌ | Quickshell is one process on Wayland layer-shell. macOS has no way to draw an equivalent panel. Not portable. |
| Themed lock screen | macOS lock screen | ❌ | Not portable. The macOS lock screen cannot be restyled. |
| Window groups, pin, per-window opacity | None | ❌ | Hyprland dispatchers with no AeroSpace equivalent. Not portable. |
| Scratchpad (Super+S) | None | ❌ | AeroSpace has no special workspace. Could emulate with a dedicated workspace and a toggle key; not planned unless adopters ask. |
| Gap toggle, window width save/restore | None | ❌ | AeroSpace has no runtime gap or size dispatchers. Not portable. |
| Chromium live theming | Brave, unthemed | ❌ | Needs Omarchy's Chromium micro-fork. Brave takes no theme colour from the command line. Not portable. |
| Plugin system (QML) | None | ❌ | Quickshell-specific. Not portable. |
| Installer ISO, pacman updates, Snapper snapshots, dual boot, factory reset, Plymouth, hardware and migration layer | n/a | — | No macOS meaning. Excluded from the score. |

If a gap bothers you, open an issue.

## Credits

- [basecamp/omarchy](https://github.com/basecamp/omarchy) — the original, and
  the live source of every theme this port uses.
- AeroSpace, SketchyBar, JankyBorders, Hammerspoon, Starship — the projects
  doing the actual work.

## License

MIT
