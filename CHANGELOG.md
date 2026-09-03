# Changelog

Newest first. Each entry is a sync from the private dotfiles it is exported
from, so a date here is the day the change went public, not the day it was
built.

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
