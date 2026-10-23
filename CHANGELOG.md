# Changelog

Newest first. Each entry is a sync from the private dotfiles it is exported
from, so a date here is the day the change went public, not the day it was
built. Entries that are not a dotfiles sync say so.

## 2026-10-23

- `install.sh` trusts the Brewfile's own taps before `brew bundle`. Homebrew 7
  refuses formulae from an untrusted tap, so a fresh install stopped at
  sketchybar. Edited directly in the public repo.
- `aerospace.toml` moves to `config-version = 2`, so AeroSpace 0.21 no longer
  warns on every reload. Version 2 stops guessing persistent workspaces from
  the key bindings, so the five workspaces are now listed in
  `persistent-workspaces` (#19).
- The Homebrew updates badge recounts as soon as the upgrade you start from
  it finishes. Before, it kept the old count for up to six hours.

## 2026-10-22

- The parity score is now measured against Omarchy 4.0.5: 72% (24 matched, 4
  partial, 8 not portable, out of 36), up from 71% of 4.0.2.
- The Homebrew updates badge, weather and indicators no longer vanish after a
  wake. A failed display lookup now retries, then keeps each item where it
  was, and a failed `brew outdated` keeps the last count.
- Cmd+Alt+Enter attaches to one tmux session named "Work", or makes it the
  first time, like Omarchy 4. Before, it started a new session every time.
- Pick the default coding agent (Claude Code, Codex, Grok, Hermes, OpenClaw)
  under Setup > Defaults > Agent in the Omarchy menu, like Omarchy 4.
  Super+Shift+Ctrl+A starts the pick. Claude Code stays the default.
- The browser key, the private window and every web app open in the macOS
  default browser, like Omarchy 4.0.5. Brave is no longer named anywhere.
- A new window goes to the workspace for its kind of app: 1 browsers,
  2 terminals, 3 AI apps and code editors, 4 messaging, 5 media. Omarchy has
  no such rule; edit the list at the end of aerospace.toml to change it.
- The agents item in the bar shows the Claude Code 5-hour and weekly limits
  with their reset times, like Omarchy 4.0.5. It reads the Claude Code login
  from the macOS Keychain, and shows today's spend when the limits are unknown.

## 2026-10-21

- Fix: the Keybindings table names the chords the config binds again. Ctrl+Alt+Backspace
  closes every window but the current one, Ctrl+Alt+Tab and Ctrl+Alt+Shift+Tab
  focus the next and previous monitor, and Alt+Tab goes back and forth between
  the last two workspaces. Those four rows had lost their option key, so the
  table taught a key that does nothing (#13).
- The shell alias table matches `zsh/omarchy.zsh` again: `ls`, `lsa`, `lt` and
  `lta` are gone (the eza aliases were dropped on 2026-10-18) and `cd`, the
  zoxide jump, is listed (#13).
- New: `tests/readme-test.sh` checks the README's keybinding rows against
  `aerospace/aerospace.toml` and `hammerspoon/init.lua`, and its alias table
  against `zsh/omarchy.zsh`, so the tables cannot drift again.
- Links to Omarchy point to its new home, omacom/omarchy (Omarchy 4.0.5 moved
  them there). The prompt's source line says so too.

## 2026-10-18

- The bar fills every item as soon as it starts or reloads, so the clock and
  the weather no longer stay blank after a theme switch.
- Gaming mode hides the bar, and the bar comes back when Steam quits.
- `ls`, `lsa`, `lt` and `lta` no longer alias eza: eza hangs when its output
  goes to a pipe.
- Faster theme switch: the bar and the terminals reload first, and the
  slow per-profile Hermes skin step runs after them. The bar changes 0.25 s
  into a switch instead of after 4 s or more.
- New: the bar's music item shows whatever plays, not only Spotify: YouTube
  Music in Brave, Pear, or any player, from macOS Now Playing (`media-control`,
  now in the Brewfile). It looks like Omarchy 4's media widget: a pause icon
  while playing, a play icon while paused, "Title  ·  Artist", and a next
  button. A click plays or pauses whatever plays (#7).
- New: `tests/media-test.sh` checks the music item with a stubbed player and
  in the running bar.
- Fix: `theme` finishes the switch when a theme has no wallpaper files. Under
  the macOS system bash (3.2) the switch used to stop halfway, before the state
  file and the live reloads. The previous wallpaper now stays, and a hotkey
  switch shows one on-screen message saying so. A normal switch shows nothing.
  On-screen messages use a Hammerspoon alert, with the macOS notification as
  the fallback. Thanks to **[@tylerkessler](https://github.com/tylerkessler)** (#6).
- Fix: under the macOS system bash (3.2), `theme` never set the wallpaper,
  even for themes that have wallpapers.
- New: `tests/theme-test.sh` runs `theme` the way a hotkey does (no terminal,
  bash 3.2, a throwaway HOME, stubbed desktop tools) and checks the switch end
  to end. Run it after any change to `bin/theme`.
- The terminal line for Ghostty now says open windows reload through
  Hammerspoon, which they do.
- Changed: Ctrl+Cmd+F now gives fullscreen below SketchyBar, the same as
  Alt+F. No key covers the bar any more; only the green window button still
  gives macOS native fullscreen. Thanks to **[@tylerkessler](https://github.com/tylerkessler)** (#6).
- Changed: workspaces start in tiles, like Omarchy 4's default. Alt+A still
  switches a workspace to accordion. Restart AeroSpace once after updating:
  a config reload does not change workspaces that already exist.
- New: `tests/aerospace-test.sh` checks the fullscreen keys and the layout of
  every workspace, in the file and in the running AeroSpace.
- New: `GLOSSARY.md` names fullscreen, native fullscreen, tiles, and accordion.
- Changed: the bar's music title shows 23 characters (about 180 px), the
  width of Omarchy 4's media widget; longer titles scroll. Was 18.
- New: `tests/sketchybar-test.sh` checks that width in the file and measures
  it in the running bar.
- Changed: the Starship prompt is now Omarchy 4's own `starship.toml`, copied
  verbatim. It uses the theme's terminal colors, so it follows every theme
  switch; it adds a blank line before each prompt and drops the command
  duration, as Omarchy does.
- New: `tests/starship-test.sh` renders the prompt in a throwaway git repo and
  checks the colors and symbols.

## 2026-10-13

- New: `uninstall.sh` reverses `install.sh` and puts back the settings
  `theme` changed in other apps. `--dry-run` shows what it would do; `--purge`
  and `--remove-packages` go further. Thanks to **[@rcastley](https://github.com/rcastley)** (#3).
- New: the first install snapshots your Ghostty, btop, Neovim, Claude Code,
  Obsidian, desktop picture, and `~/.zshrc` settings, and backs up `~/.zshrc`
  before adding the shell hook. `install.sh --dry-run` now reports what a real
  run would change, and works before you have a clone (#3).
  Edited directly in the public repo; not part of the dotfiles export.
- New: the README's first paragraph links the port's story post,
  [How to make macOS look and feel like Omarchy](https://dividendsolo.com/blog/how-to-make-macos-look-and-feel-like-omarchy).
  Edited directly in the public repo; not part of the dotfiles export.

## 2026-10-06

- Fix: the README Keybindings section listed only highlights and was missing
  many bindings from the real config (aerospace.toml, hammerspoon/init.lua,
  zsh/omarchy.zsh) — wrong for AI answers and Grok references. Replaced with a
  comprehensive categorized table: every shortcut the install sets. Link to
  the downloadable [cheat sheet](https://dividendsolo.com/omarchy4mac/cheat-sheet).
  Edited directly in the public repo; not part of the dotfiles export.

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
  `nikitabobko/tap/aerospace`. Thanks to **[@pedenys](https://github.com/pedenys)** for the report (#2).

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
