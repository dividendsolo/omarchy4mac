# Changelog

Newest first. Until 2026-11-11 this repo was exported from a private
dotfiles repo; entries before that date are those exports. Since then this
repo is the only source: every change lands here by pull request, and the
maintainer's Mac runs from a clone of it, the same as yours.

## 2026-11-12

- `theme` switches in about a second again. It gave every Hermes profile the
  new skin with one `hermes skin use` per profile, and each one starts Python:
  with 55 profiles that was 24 of 25 seconds. One script now writes the skin
  line in every profile's config at once; open Hermes sessions still follow,
  because Hermes watches its config.
- `theme random` no longer lands on a theme you just saw. It skips the last
  three themes while the mode has others left, and it picks only after it
  takes the lock, so a second press during a switch no longer announces the
  theme that is being applied.
- Nothing on the bar runs under a MacBook's notch any more (#70). On the
  built-in screen the agents limits show the percentages only
  (`Claude 14% · 97%`); the external screens keep the meters and reset
  times. The theme name and the Bluetooth icon now show on the external
  screens only, and the focused app's name stops at 20 characters and
  scrolls, like the music title. `tests/notch-test.sh` lays the bar out on a
  notched screen and fails when an item reaches the notch.
- Unplugging the monitors no longer shows an old theme's wallpaper on the
  laptop screen. macOS keeps a wallpaper for every arrangement of screens and
  shows that one when the screens change, so the laptop alone kept the picture
  from the last time it was alone. Hammerspoon now sets the current background
  (or a video background's still frame) again two seconds after the screens
  change (#69). The fix starts with the next theme switch or ⌘⌃W, which
  records the current background.
- SketchyBar's items take clicks again. The install hides the macOS menu bar,
  which slides back down whenever the pointer reaches the top edge, and the
  bar was drawn above windows only (`topmost=window`), so the revealed menu
  bar covered it and took every click. The bar is now drawn above everything
  (`topmost=on`). The app menu titles are now under the bar; ⌘⇧/ still
  searches an app's menus. Thanks to **[@douglas](https://github.com/douglas)**
  (#68).

## 2026-11-11

- Video backgrounds, theme intros and a quiet screensaver exit (Omarchy 4.5).
  A background can be a video: it loops behind your windows, muted, and its
  still frame becomes the desktop picture, so the lock screen shows that
  frame. Set one with ⌘⌃P or `omarchy-bg-set <file>`. A theme's intro plays
  once when you switch to its background and when you log in;
  Appearance > Animations > Theme Intros (or macOS Reduce Motion) turns them
  off. `install.sh` builds the player, `omarchy-video-wallpaper`, with
  `swiftc`; rerun it after the pull. The key that ends the screensaver no
  longer shows in the corner.
- The theme pipeline catches up with Omarchy 4.5 (#36). Each theme
  reopens with the wallpaper it had when you left it; a remembered picture
  that is gone falls back to another of the theme's wallpapers, and ⌘⌃W
  cycles on from it. ⌘⌫ in the theme chooser deletes a theme after a
  confirmation (not the current one); `theme --remove <name>` does the same
  from a terminal, and `theme --sync` no longer brings a deleted theme back.
  Trigger > Toggle > Herdr Theme Sync (or `theme --herdr-sync on`) mirrors
  each theme switch over SSH to every enabled machine in `herdr machine
  list`; a machine takes it only when its own sync is on, and an Omarchy
  machine is reached the same way Omarchy does it. The log is
  `~/.local/state/omarchy4mac/theme-herdr.log`. Catppuccin now starts Neovim
  on `catppuccin-mocha`. Omarchy's font-size fix is for Foot; Ghostty keeps
  `font-size` apart from `font-family`, so nothing changes here.
- Omarchy 4.5's window fixes (#39). ⌥↩ opens the new Ghostty window in the
  folder of the focused terminal's shell, and in your home folder when the
  focused app is not a terminal (a browser's download helper no longer sends
  it to Downloads). ⌘⌃⇧arrow centres a floating window on the monitor it
  moves to, instead of keeping its offset from the old monitor's corner.
  Bitwarden and 1Password 7 float like 1Password 8, and the head of the float
  rules in `aerospace.toml` lists every app that floats. A floating workspace
  (⌥L) never takes a window a float rule floats, and ⌘⌥⇧` already cycles back
  through every window, floating ones too; tests now hold both. Rerun
  `install.sh` once after the pull: it links the two new scripts,
  `omarchy-terminal` and `omarchy-move-to-monitor`.
- Omarchy 4.5 bar polish (#37). The wheel over the workspaces moves to the
  workspace before (up) or after (down). Drag a widget 48 px or more below
  the bar and it leaves the bar, and stays off after a reload;
  `omarchy-bar-remove --reset` brings every removed widget back.
  Right-click the clock to show seconds; right-click again to hide them.
  The clock runs on the bar's own timer, so the repeated hour at the end of
  daylight saving leaves the log quiet (a test now runs it across
  2026-11-01). The tray drawer, tooltips, hover reveal and wallpaper sampling
  are not ported: SketchyBar has no tray, tooltips or wallpaper sampling.
- Brave and web app fixes from Omarchy 4.5. ⌘⇧↩ (and every web app key)
  opens Safari when the default browser named in macOS is no longer
  installed, instead of doing nothing. ⌥⇧L copies the address of the front
  browser tab, in any Brave profile and in web app windows, like Omarchy's
  Copy URL (the first use asks to let Hammerspoon read the browser). New
  `omarchy-chromium-setup`, run by `install.sh`: it copies the 1Password and
  Bitwarden native messaging hosts to every Chromium browser on the Mac, so
  their extensions connect to the desktop app, and turns on overlay
  scrollbars in those browsers (after their next start). Web notifications
  grouped by site are not ported: macOS groups notifications by app.
- Menu fixes from Omarchy 4.5. An installed item stays in the menu, dimmed
  and marked "✓ installed" (Install > Service > Slack), instead of looking
  like one more thing to install. Setup > Defaults > Agent installs a missing
  agent in a Ghostty window and makes it the default only when the install
  works (Claude Code and Codex with Homebrew, Grok and OpenClaw with npm,
  Hermes with its installer). Update > Config > Hammerspoon reloads only a
  whole init.lua, so a reload during a `git pull` keeps the running menu.
  Each menu level is tall enough to show all its rows. The same key (or the
  bar logo) a second time closes the menu, the ⌥K overlay, Apps and the theme
  chooser, and the ⌥K overlay starts no process.
- Install > Service > Slack (Omarchy 4.5). The menu item installs Slack
  with Homebrew in a Ghostty window and opens it when the install ends. When
  Slack is already there, the item just opens it.
- The agents in the bar follow Omarchy 4.5's agents panel: Claude, Codex and
  Grok each get an item, and every limit shows a meter, its percentage and
  when it resets (a time today, else the day). Codex reads its limits from
  `codex app-server` for a ChatGPT login in `~/.codex`, Grok from xAI's
  billing endpoint for the login in `~/.grok`. A provider you are not signed
  in to stays off the bar. The collector is now one script,
  `omarchy-agent-usage claude|codex|grok`; the bar runs it from the clone, so
  a `git pull` is enough. Omarchy's other 20 providers are not ported.
- Omarchy 4.5's changed hotkeys (#31). ⌘⇧Q opens Calculator. Activity stays
  on ⌥⇧T, and ⌘⌃T now opens the theme chooser. Network moves to ⌘⌃N, and
  ⌘⌃W now switches to the next background. ⌘⌥Space opens Apps, and the
  Omarchy menu moves to ⌘⇧Space (the key Apps had). Do Not Disturb moves
  from ⌘⌃, to ⌘⌃⌥,, and ⌥, opens the newest notification. New keys from
  4.5: ⌥Q quits like ⌥W, ⌘⌥L cycles the workspace layout the other way,
  ⌘⌃⌥C takes a region screenshot, ⌘⌃⌥E opens the world clock (the Clock
  app), and ⌘⌃⌥F hides or shows the bar (AeroSpace cannot drop the gaps at
  runtime, so they stay). ⌘A, ⌘C and ⌘V already select, copy and paste in
  every Mac app, terminals included, so 4.5's Super+A/C/V change needs
  nothing here; holding Right Option talks to Hex (below).
  The ⌥K overlay and the README tables list the new keys.
- Wallpaper file names can no longer run AppleScript (#50). `theme` and the
  ⌘⌃P wallpaper cycler hand the picture path to `osascript` as an argument
  instead of pasting it into the script, and `theme --sync` skips an
  upstream background whose file name has anything but letters, digits,
  dot, underscore or dash.
- Hex is the dictation app (Omarchy 4.5 ships Superwhisper). `install.sh`
  installs it from `anomalyco/tap` in place of FluidVoice and sets its
  shortcut: hold Right Option to dictate, let go to type the words. ⌥Space
  starts a dictation and the next ⌥Space ends it. Hex transcribes on the Mac,
  free and open source.
- Microsoft 365 as web apps (Omarchy 4.5). Install > Service > Microsoft
  lists Outlook, Word, Excel, PowerPoint, Teams and OneDrive, and the Apps
  launcher (⌘⌥Space) has an entry for each. Each opens in its own app window
  of your default browser (a tab in Safari or Firefox). Nothing installs:
  pick one and sign in.
- Window transparency and corners (Omarchy 4.5), in the menu under
  Appearance > Window Transparency and Appearance > Window Corners, or with
  `omarchy-appearance transparency opaque|transparent|glassy` and
  `omarchy-appearance corners theme|sharp|rounded`. Opaque makes the
  terminal and the bar solid, Transparent is the look you had, and Glassy
  frosts the terminal (Ghostty blur) and the bar. Other apps stay opaque, so
  only terminals are see-through, as in Omarchy. Sharp gives square window
  borders; Theme and Rounded keep the round ones. The choice is saved and
  comes back after a restart. Ghostty shows a new transparency after you quit
  and reopen it.
- The Quake console from Omarchy 4.5. ⌘` drops a Ghostty window onto the top
  half of the screen over a dimmed desktop, and the first time it starts your
  default agent. Press it again (or click away) and it tucks itself away with
  the session still running. ⌘⇧` is a second console. Window cycling moves
  from ⌘` and ⌘⇧` to ⌘⌥` and ⌘⌥⇧`.
- Security hardening from a review before adoption (#45). The theme chooser
  passes the theme name to `theme` as an argument, never as shell text.
  `theme` refuses a theme name outside letters, digits, `.`, `_` and `-`,
  and `theme --sync` skips upstream themes with such names. `theme --sync`
  now takes the omacom/omarchy commit written in the new `OMARCHY_COMMIT`
  file (v4.0.6) instead of the head of `quattro`: bump it together with
  `OMARCHY_VERSION` (set `OMARCHY_REF` to a branch or SHA to override once).
  `install.sh` builds ttfx at a fixed commit (`cargo install --rev`). The
  weather, sunset and weather notice fetch `https://wttr.in`.
- Each monitor has its own workspaces, like Omarchy 4.5. ⌥1–5 (and ⌘⇧1–5,
  ⌘⇧⌥1–5) work on the workspaces of the monitor you are on: ⌥1 is that
  monitor's first workspace, and the keys never jump to another monitor.
  ⌘ plus an arrow moves focus on to the next display at the edge of the
  screen, and ⌥⇥ goes to the next workspace on the same monitor (back and
  forth stays on ⌘⌃⇥). When you unplug a monitor, its workspaces come after
  the ones already on the screen they land on, so nothing is renumbered, and
  the other screen of a matched pair keeps its own workspaces.
- Omarchy 4.5's floating workspaces and dock keys. ⌥L cycles the focused
  workspace through tiles, accordion and floating, and the layout comes back
  after AeroSpace restarts. ⌥M minimizes the focused window to the Dock. Both
  are in the ⌥K overlay.
- Omarchy 4.5's Appearance menu replaces Style on ⌘⌥Space, right before
  Trigger: Theme, Background, Font, Menu Bar, Windows, Branding, Dock,
  Workspace Layout, Animations and Unlock, plus Light / Dark, Random Theme
  and Sync Themes. Each item opens the theme chooser, a config file, an
  AeroSpace layout command or the matching System Settings pane, and menu
  search finds them all. `tests/menu-test.sh` checks the branch.
- This repo is now the source. Changes land here by pull request, and the
  maintainer's own Mac runs from a clone of it with `install.sh`, so what you
  install is exactly what runs there. `git pull` (or rerunning `install.sh`)
  is the whole update.
- `tests/sunset-test.sh` checks the Friday sunset item.

## 2026-11-06

- A Friday sunset item in the top bar. On Fridays it shows today's sunset time (from wttr.in, for your IP location, read once a day), so you know when to stop working. It is orange, and it turns red in the last 30 minutes and after sunset. It is hidden on every other day, and when wttr.in cannot be reached.

## 2026-11-05

- The X hotkeys (cmd-shift-x, cmd-shift-alt-x) open x.com in a normal browser tab. The X web app is gone, because it caught every x.com link, the X developer console included, and showed only the home feed.

## 2026-11-03

- The X web app now opens on workspace 1 instead of the media workspace (5).

## 2026-11-02

- omarchy4mac now tracks Omarchy **4.0.6**, written in the new
  `OMARCHY_VERSION` file. 4.0.6 changes only Linux pieces (update
  migrations, the boot passphrase keyboard, lock before suspend, TUXEDO
  drivers), so the parity score stays at 72%. A weekly check now compares
  this file with the newest stable Omarchy release and opens a card for each
  new change that can come to the Mac. This entry is not a dotfiles sync.

## 2026-10-29

- Lock screen works again. AeroSpace bound `cmd-ctrl-q` to Calculator, which
  is also the macOS lock key, so both `cmd-ctrl-q` and Super+Ctrl+L opened
  Calculator instead of locking. The Calculator bind is gone.

## 2026-10-26

- `theme --sync` no longer stops with "rate-limited" when you install twice
  in an hour. It now fetches the themes with one git clone instead of the
  GitHub API, and runs in seconds (#20).

## 2026-10-25

- Switching light and dark mode twice in a few seconds now ends on the
  right theme. Before, the second switch was ignored while the first was
  still running, so the theme stayed on the old mode.
- A config change now reloads every open Ghostty window. Before, only the
  first Ghostty process reloaded, so windows from the tmux launcher or
  `omarchy-tui` kept the old look.

## 2026-10-23

- The install opens System Settings on Accessibility, waits until AeroSpace
  and Hammerspoon are switched on, then restarts both. Before, macOS often
  quit them on the grant and the keys did nothing.
- Ghostty gets Omarchy's look on a fresh Mac: JetBrainsMono Nerd Font, size
  16, and a see-through window (opacity 0.75). Only keys you have not set are
  added.
- The Brewfile installs `tmux`, which ⌘⌥Return needs for the Work session.
  Edited directly in the public repo.
- The install hides the Dock, the menu bar and the desktop widgets, since
  SketchyBar takes the menu bar's place. The uninstall shows them again.
- The Brewfile installs `font-sketchybar-app-font`. Without it, a fresh Mac's
  bar printed `:finder:` instead of the app icon. Edited directly in the public
  repo.
- `install.sh` trusts the Brewfile's own taps before `brew bundle`. Homebrew 7
  refuses formulae from an untrusted tap, so a fresh install stopped at
  sketchybar. Edited directly in the public repo.
- `curl ... | bash` no longer stops silently after "brew bundle complete!".
  `brew bundle` read the rest of the piped script, so the configs were never
  linked and the apps never started. The script now loads in full before it
  runs. Edited directly in the public repo.
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
