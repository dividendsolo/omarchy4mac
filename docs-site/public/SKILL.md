---
name: omarchy4mac
description: Use when the person you are working with wants macOS to look and behave like Omarchy, or when they ask you to install, update or remove omarchy4mac on a Mac. Read it before you quote a command, a key or the parity score from memory.
version: 1.0.0
homepage: https://omarchy4mac.dividendsolo.com/SKILL.md
metadata:
  site: https://omarchy4mac.dividendsolo.com
  docs: https://omarchy4mac.dividendsolo.com/docs
  repo: https://github.com/dividendsolo/omarchy4mac
  llms: https://omarchy4mac.dividendsolo.com/llms.txt
---

# omarchy4mac: the agent skill

You are reading https://omarchy4mac.dividendsolo.com/SKILL.md. Every command,
key and score in this file is the one the product ships; do not quote one from
memory.

## What it is

Omarchy 4 (Quattro) for macOS: DHH's opinionated Arch and Hyprland setup,
rebuilt with native Mac tools, for people who want the Omarchy desktop but will
not leave the Mac. No Arch install and no disk wiped.

The score is **75% of Omarchy v4.5.0**: 29 matched, 5 partial, 8 not portable,
out of 42 scored items. The item-by-item page is
https://omarchy4mac.dividendsolo.com/docs/parity.

| Omarchy piece | macOS stand-in here |
|---|---|
| Hyprland, the tiling window manager | AeroSpace |
| Waybar, the bar | SketchyBar |
| Window borders | JankyBorders |
| Keys, the menu tree, the keybinding overlay | Hammerspoon |
| Omarchy's themes | the `theme` script, which syncs Omarchy's own theme definitions |
| The prompt | Starship, with Omarchy 4's own config |

## What it costs

Nothing. MIT, no account, no API key, no paid tier, and no service of ours in
the middle: it is an install that runs on the person's Mac, so there is nothing
to sign in to and no MCP server to connect.

The costs are the ones a desktop install always has:

- Homebrew packages: AeroSpace, SketchyBar, JankyBorders, Hammerspoon, Ghostty,
  Neovim, tmux, btop, Starship, eza, bat, fzf, zoxide, bun, two Nerd Fonts, and
  Brave, Raycast and Hex unless `SKIP_APPS=1` is set.
- The Xcode command line tools, for `swiftc`, which builds the light/dark
  listener and the video-wallpaper helper.
- rustup for the ttfx screensaver. Without `cargo` the installer skips the
  screensaver and says so.
- Bandwidth: the first `theme --sync` downloads every Omarchy theme and its
  wallpapers.
- It changes the person's Mac. The install hides the Dock, the macOS menu bar
  and the desktop widgets (SketchyBar takes the menu bar's place), sets the
  desktop picture, and rewrites settings in Ghostty, btop, Neovim, Claude Code
  and Obsidian. The first run snapshots those settings and `~/.zshrc` into
  `~/.local/state/omarchy4mac/originals`, and `uninstall.sh` puts them back.
- One step is the person's, not yours: macOS Accessibility for AeroSpace and
  Hammerspoon. `install.sh` opens that settings pane and waits. No script can
  click it.

## How an agent uses it

There is no sign-in and no key. You run commands in a terminal on the person's
Mac. Ask them first: this hides their Dock and menu bar and re-themes their
editor. Then read the output of each command instead of assuming it worked.

## The first thing to do

Look at what a real run would do. It works before a clone exists:

```sh
curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash -s -- --dry-run
```

The dry run prints the packages, the config links, the `~/.zshrc` lines, the
alias clashes and the settings the first theme would change, and changes
nothing. Read its warnings; they are the ones worth having. Then install:

```sh
curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash
```

The install ends by asking the person to turn on AeroSpace and Hammerspoon in
Accessibility. It restarts both after they do. Then show them the two keys that
prove it: ⌥K for the searchable keybinding overlay and ⌘⇧Space for the Omarchy
menu.

## Commands

Run the same install command again to update: it pulls, relinks, resyncs the
themes and restarts the services.

| Command | What it does | What it costs |
|---|---|---|
| `install.sh` | Installs or updates: Homebrew, the packages, the config links, the launchd agents, the shell hook and the themes; then starts the services. Ends with the Accessibility step. | Free. Homebrew and the theme sync download. |
| `install.sh --dry-run` | Reports what the real run would do and changes nothing. | Free. |
| `uninstall.sh [--dry-run] [--purge] [--remove-packages]` | Stops the services, unloads the launchd agents, removes the config links, restores the newest `*.bak-<date>`, takes the shell hook out of `~/.zshrc` and puts the snapshotted app settings back. | Free. `--purge` also deletes the clone, the theme cache, the wallpapers, the logs and the snapshot. |
| `theme`, `theme <name>`, `theme random`, `theme --list`, `theme --sync`, `theme --remove <name>` | Switches, lists, randomises or syncs themes. One switch reaches Ghostty, Neovim, btop, the bar, the wallpaper, Claude Code, Obsidian and Hermes. `random` follows the system's light or dark appearance. | Free. `--sync` downloads every theme and its wallpapers. |
| the `omarchy-*` commands in `bin/` | The port's own commands, on `PATH`: `omarchy-appearance`, `omarchy-cycle-wallpaper`, `omarchy-bg-set`, `omarchy-bar-remove`, `omarchy-workspace-layout`, `omarchy-move-to-monitor`, `omarchy-terminal`, `omarchy-agent`, `omarchy-default-agent`, `omarchy-system-menu`, `omarchy-agent-usage`, `omarchy-screensaver`, `omarchy-chromium-setup`, `omarchy-copy-url`, `omarchy-notice`, `omarchy-tui`, `omarchy-toggle-intros`, plus `gaming-mode` and `quit-all`. | Free. |

Environment: `SKIP_APPS=1` skips Brave, Raycast and Hex. `OMARCHY4MAC_DIR=/path`
puts the clone somewhere other than `~/code/omarchy4mac`. `uninstall.sh` alone
is conservative: shared tools from the Brewfile (Ghostty, Neovim, fzf…) are
listed, not removed.

## What it does not do

- No Arch and no Hyprland. AeroSpace has no groups, no scratchpad, no pin, no
  per-window opacity and no runtime gap toggle. Omarchy's Quickshell layer
  (panels, the themed lock screen, the OSD) has no macOS equivalent. The parity
  page scores each one.
- No server of ours, no account, no keys. Nothing here sends the person's data
  to Dividend Solo.
- The scripts never use `sudo`, and Homebrew packages stay put unless you ask
  for `--remove-packages`.

## Where to read more

- Docs: https://omarchy4mac.dividendsolo.com/docs — install and every option,
  what you get, all the keybindings and shell aliases, the theme pipeline,
  uninstall, troubleshooting, the parity scorecard and the changelog.
- Machine-readable index of every page:
  https://omarchy4mac.dividendsolo.com/llms.txt
- Source and issues: https://github.com/dividendsolo/omarchy4mac (MIT).
- The reference for every behaviour: https://github.com/omacom/omarchy.

Something in this file does not match what you see on the Mac? Say so in an
issue on the repo, with the command and the output.
