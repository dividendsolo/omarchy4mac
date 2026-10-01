# Changelog

Newest first. Each entry is a sync from the private dotfiles it is exported
from, so a date here is the day the change went public, not the day it was
built.

## 2026-10-01

- Fix: Ghostty hung (force quit needed) after a theme switch. The reload
  signal (SIGUSR2) hangs Ghostty 1.3.1 when sessions are open, and the
  light/dark watcher sent it on every appearance change. `theme` no longer
  live-reloads Ghostty. New windows get the new theme; press Cmd-Shift-, to
  reload open windows.

## 2026-09-30

- Fix: a fresh install failed at `brew bundle` with "No Cask with this name
  exists" for `aerospace`. AeroSpace is not in homebrew/cask; it ships from
  its author's tap. The Brewfile now taps `nikitabobko/tap` and installs
  `nikitabobko/tap/aerospace`. Thanks to @pedenys for the report (#2).

## 2026-09-21

- Fix: a theme switch triggered by the macOS light/dark flip skipped the
  Hermes skin step in silence, so every Hermes session kept the old skin
  (light text on a dark terminal, or the reverse). The appearance watcher
  now puts `~/.local/bin` on its PATH, and `theme` resolves `hermes` by
  path and says so when it cannot. Running sessions pick the skin up live;
  no restart needed.
- New: a stand-up / sit-down indicator in the bar (`sketchybar/plugins/standup.sh`).
  It reads a 30-minute interval timer at `~/.hermes/standup_timer.sh` and
  stays hidden when no timer runs, so it is inert unless you have one.

## 2026-09-16

- New: a Sponsor button on the repo (`.github/FUNDING.yml`, GitHub Sponsors
  for `dividendsolo`). The port stays free; this is how to tip it if it
  earned a place on your Mac.

## 2026-09-09

- New: the theme switch reaches Hermes. The Hermes CLI paints its own skin
  and ignores the terminal palette, so its default gold skin was unreadable
  on a light Ghostty. `theme <name>` now runs `hermes skin use daylight` for a
  light theme and `hermes skin use default` for a dark one (skipped when
  hermes is not installed), on the default profile and every named profile.
  Restart Hermes to see it.
- Fix: `herdr/config.toml` carries `onboarding = false` so herdr skips its
  first-run screen.

## 2026-09-08

- New: Herdr, Omarchy 4's agent multiplexer, is ported. `brew install herdr jq`,
  symlink `herdr/config.toml` to `~/.config/herdr/config.toml` (Omarchy's
  config, verbatim; the theme is the terminal palette, so `theme` reaches it
  with no template). ⌘⌃↩ opens Ghostty with herdr, `h` is the alias, and the
  `hdl`, `hds`, `hdlm`, `hsl` layout functions are in `zsh/omarchy.zsh` with
  `emulate -L ksh` so Omarchy's bash bodies run unchanged in zsh. The parity
  doc had filed herdr as Linux-only; it is not. Run `aerospace reload-config`
  and reload Hammerspoon once after updating.

## 2026-09-05

- New: `bin/quit-all` quits every Dock app except Finder. Bound to ⌘⌃⇧Q in
  Hammerspoon and listed in the control menu under Toggle. Symlink it into
  `~/.local/bin` and reload Hammerspoon once after updating.

## 2026-09-03 (workspaces)

- Change: apps no longer jump to a fixed workspace on open. Omarchy 4 sends
  nothing to a preset workspace; a window opens where you are. The browser,
  terminal, Claude, chat, and music rules that moved windows to workspaces
  1 to 5 are gone. Browsers still open tiled and the screensaver still
  floats. Run `aerospace reload-config` after updating.

## 2026-09-03 (later)

- Fix: open Ghostty windows now pick up a theme change at once. The
  appearance listener (launchd) cannot drive Ghostty's Reload Configuration
  menu (no Accessibility permission), so Hammerspoon watches both Ghostty
  config files and clicks it. Reload Hammerspoon once after updating.
- Hammerspoon accepts AppleScript (`hs.allowAppleScript(true)`), so scripts
  can reload it.

## 2026-09-03: audit fixes

- Brewfile taps `FelixKratz/formulae` (sketchybar and borders are not in core),
  adds `bun` and `fastfetch`. `sketchybar/colors.sh` is generated, now ignored.
- Installer loads the light/dark launchd agent only when the listener compiled.
- Menu Setup items resolve the repo from the init.lua symlink instead of a
  hard-coded path. Screensaver text and gaming mode no longer assume one machine.

## 2026-09-03: one-command install

- `install.sh`: Homebrew if missing, `Brewfile`, every symlink (existing files
  backed up), the light/dark listener, both launchd agents, the shell file,
  `theme --sync`, services. Rerun it to update. `--dry-run` prints the plan.
- `Brewfile` lists everything, including the apps the bindings count on
  (`SKIP_APPS=1` leaves those out).

## 2026-09-03: renamed to omarchy4mac

- The repo is now `dividendsolo/omarchy4mac`: Omarchy 4, for the Mac. GitHub
  redirects the old `omarchy-mac` URL. Update your remote:
  `git remote set-url origin https://github.com/dividendsolo/omarchy4mac.git`.

## 2026-09-03: ⌥T shuffles the theme

- `alt-t` is bound in AeroSpace to `theme random`, so the shuffle key ships
  with the repo. It used to be a Raycast script command on one machine.

## 2026-09-03: Omarchy 4 (Quattro) parity pass

Everything below was built against Omarchy v4.0.2, branch `quattro`, repo
`omacom/omarchy`. The checklist and what cannot be ported are in
`docs/parity-v4.md`.

- **Themes** now sync from the v4 repo layout and render from Omarchy's own
  templates, so every theme Omarchy adds shows up here with `theme --sync`.
  A theme switch also recolors Claude Code and Obsidian.
- **Web apps** open as Brave app windows on the v4 bindings (⌘⇧ + letter):
  HEY mail and calendar, Google Chat, Google Photos, YouTube, Grok, X.
- **Menu tree** on ⌘⌥Space matches the v4 root: Apps, Learn, Trigger, Style,
  Setup, Install, Update, System. Nested search. ⌘Esc opens System directly.
- **Bar** follows the v4 layout: logo opens the menu, workspaces, then
  indicators, weather, a Homebrew updates badge, and a coding-agents spend
  widget (today's Claude Code cost via ccusage). Per-display placement.
- **Utility keys** from v4: emoji picker, clipboard history, caffeinate toggle
  with a bar indicator, lock, gaming mode (⌘⌃G).
- **Screensaver**: ttfx ASCII art after 150 s idle, one window per display,
  Omarchy style. Toggle and force-launch scripts included.
- **Shell**: Omarchy 4 aliases and env defaults (eza, bat, fzf, zoxide, git
  shorthands) in `zsh/omarchy.zsh`.
- **Cheat sheet** (⌥K) lists every AeroSpace binding, 12 new rows.
- **Float toggle** moved from ⌥T to ⌥S.
- **Coding agent** in a fresh Ghostty on ⌘⇧⌃A, like v4.

## 2026-08-17: first public release

AeroSpace + SketchyBar + JankyBorders + Hammerspoon, the Omarchy theme
switcher with instant light/dark, wallpaper cycling, the system menu, and the
keybinding overlay. Parity audit against Omarchy v4.0.0 in `AUDIT.md`.
