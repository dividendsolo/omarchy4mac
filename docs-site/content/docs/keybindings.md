---
title: Keys and aliases
description: "Every binding from the real config: AeroSpace, Hammerspoon and zsh."
---

## Keybindings

Press **⌥K** for the searchable overlay. Every binding from the real config
(aerospace.toml, hammerspoon/init.lua, zsh/omarchy.zsh) is below.
A downloadable one-page [cheat sheet](https://dividendsolo.com/omarchy4mac/cheat-sheet)
is also available.

### Launching

| Keys | Action |
|---|---|
| ⌥↩ | Ghostty (terminal), in the focused terminal's folder, else in your home folder |
| ⌘⌥↩ | Ghostty + tmux (attaches to the session "Work", or makes it) |
| ⌘⌃↩ | Ghostty + herdr (agent multiplexer) |
| ⌘⇧↩ | Browser (macOS default; Safari when that browser is gone) |
| ⌘⇧⌥B | Browser (private window) |
| ⌘⌥C | Chrome |
| ⌘⇧F | Finder |
| ⌘⇧N | Ghostty + nvim |
| ⌘⇧D | Ghostty + lazydocker |
| ⌘⇧M | Spotify |
| ⌘⇧Q | Calculator |
| ⌘⇧A | Claude |
| ⌘⇧⌥A | Grok (app window) |
| ⌘⇧O | Obsidian |
| ⌘⇧W | Typora |
| ⌘⇧G | Signal |
| ⌘⇧⌥G | WhatsApp |
| ⌘⇧⌃G | Google Chat (app window) |
| ⌘⇧P | Google Photos (app window) |
| ⌘⇧X | X (Twitter) |
| ⌘⇧⌥X | X: new post |
| ⌘⇧Y | YouTube (app window) |
| ⌘⇧/ | 1Password |
| ⌥⇧L | Copy the browser tab's URL (any Brave profile, web app windows too) |
| ⌘⇧C | HEY Calendar (app window) |
| ⌘⇧E | HEY Mail (app window) |
| ⌘⎵ | Raycast launcher |
| ⌥⎵ | Dictation on / off (Hex) |
| Hold right ⌥ | Dictate while held, type on release (Hex) |

### Window / Layout

| Keys | Action |
|---|---|
| ⌥W | Quit focused app |
| ⌥Q | Quit focused app (same as ⌥W) |
| ⌃⌥⌫ | Close all windows but current |
| ⌥S | Toggle floating / tiling |
| ⌥A | Toggle accordion / tiles (workspace) |
| ⌥L | Cycle workspace: tiles / accordion / floating (kept across restarts) |
| ⌘⌥L | Cycle workspace layout the other way |
| ⌥M | Minimize window (to the Dock) |
| ⌥J | Toggle tiles horizontal / vertical |
| ⌥F | Fullscreen (tile) |
| ⌘⌥F | Fullscreen (tile) |
| ⌘⌃F | Fullscreen (tile), same as ⌥F |

### Focus

| Keys | Action |
|---|---|
| ⌘←/↓/↑/→ | Focus window in direction, on to the next display at the edge |
| ⌘` | Quake console: drops over a dimmed screen, starts the default agent the first time; again to tuck it away |
| ⌘⇧` | Second Quake console |
| ⌘⌥` | Cycle next window in workspace |
| ⌘⌥⇧` | Cycle previous window in workspace |
| ⌃⌥⇥ | Focus next monitor |
| ⌃⌥⇧⇥ | Focus previous monitor |

### Move / Swap

| Keys | Action |
|---|---|
| ⌘⇧←/↓/↑/→ | Swap window in direction |
| ⌘⇧⌥←/→/↑/↓ | Move workspace to prev / next monitor |
| ⌘⌃⇧←/↓/↑/→ | Move focused window across monitors (a floating one lands centred) |

### Workspaces

| Keys | Action |
|---|---|
| ⌥1–5 | Switch to the focused monitor's workspace 1–5 |
| ⌥⇥ | Next workspace on the focused monitor |
| ⌘⌃⇥ | Back and forth between last two workspaces |
| ⌘⇧1–5 | Move window to the focused monitor's workspace N and follow |
| ⌘⇧⌥1–5 | Move window to the focused monitor's workspace N (stay on current) |

### Resize

| Keys | Action |
|---|---|
| ⌥= | Grow focused window +50 px |
| ⌥- | Shrink focused window –50 px |
| ⌘⇧= | Grow height +50 px |
| ⌘⇧- | Shrink height –50 px |

### System

| Keys | Action |
|---|---|
| ⌘⌃A | Sound settings |
| ⌘⌃B | Bluetooth settings |
| ⌘⌃N | Network (Wi-Fi settings) |
| ⌘⌃S | Share (LocalSend) |
| ⌘⌃E | Emoji picker (Raycast) |
| ⌘⌃⇧Q | Quit every Dock app (keeps Finder) |
| ⌘⌃R | Set a reminder (20m message) |
| ⌘⌃Z | Zoom (macOS accessibility) |
| ⌘⇧⌃A | Coding agent (the pick in Setup > Defaults > Agent, Claude Code by default) |
| ⌥⇧T | Activity (Ghostty + btop) |
| ⌘⌃⌥E | World clock (Clock) |
| ⌘⌃⌥F | Full screen desktop: hide or show the bar (the gaps stay) |
| ⌘⌃H | System Information |
| ⌘⌃. | HandBrake |
| ⌘⌃L | Lock screen |
| ⌘⌃I | Toggle caffeinate (keep awake) |
| ⌥, | Open the newest notification |
| ⌘⌃⌥, | Toggle Do Not Disturb |
| ⌘⌃C | Screenshot picker (⇧⌘5) |
| ⌘⌃⌥C | Screenshot of a region (⇧⌘4) |
| ⌘⌃V | Clipboard history (Raycast) |
| ⌘⌃P | Cycle wallpaper |
| ⌘⌃W | Next background (cycle wallpaper) |
| ⌘⌃G | Gaming mode |
| ⌘⌃⌥T | Date & time toast |
| ⌘⌃⌥W | Weather toast |
| ⌘⌃⌥B | Battery toast |
| ⌘⎋ | System menu (Lock / Sleep / Restart) |

### Appearance

| Keys | Action |
|---|---|
| ⌘⌥⎵ | Apps launcher (curated) |
| ⌘⇧⎵ | Omarchy control menu |
| ⌘⌃⇧⎵ | Theme chooser |
| ⌘⌃T | Theme chooser |
| ⌥T | Random theme (matches system light/dark) |
| ⌥K | Show keybinding overlay |

### Shell Aliases (zsh)

| Alias | Command |
|---|---|
| `cd` | zd (zoxide jump; real paths still `cd`) |
| `ff` | fzf (bat preview) |
| `eff` | $EDITOR (fzf result) |
| `g` | git |
| `gcm` | git commit -m |
| `gcam` | git commit -a -m |
| `gcad` | git commit -a --amend |
| `d` | docker |
| `r` | rails |
| `t` | tmux attach or new -s Work |
| `h` | herdr |
| `n` | nvim (no args: nvim .) |
| `mup` | mise up (forced) |
| `..` / `...` / `....` | cd .. / ../.. / ../../.. |
| `hdl <ai>` | Herdr dev layout (editor, AI, terminal) |
| `hds` | Herdr square (editor, diff, terminal, opencode) |
| `hdlm <ai>` | Multi-tab hdl, one per subdirectory |
| `hsl <n> <cmd>` | Swarm: N panes running `<cmd>` |

## Reading the keys

> **Note:** `⌘` = Super (Cmd), `⌥` = Alt (Opt), `⇧` = Shift, `⌃` = Ctrl,
> `⎵` = Space, `⌫` = Backspace, `⎋` = Escape, `↩` = Return, `` ` `` = Backtick.
