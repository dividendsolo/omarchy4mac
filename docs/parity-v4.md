# Omarchy v4 (Quattro) parity on this Mac

Written 2026-09-02 from the `quattro` branch of `omacom/omarchy` (v4.0.2, the
current release) and the dotfiles as they stand. One flat list, ordered by
how much of the daily feel each item buys. Tick items as they land.

## Where we stand

- The keybinding vocabulary, the workspace model, and the theme pipeline are
  ported. Roughly half of what a v4 user touches in a day exists here.
- The ceiling on macOS is about three quarters. The v4 shell (bar, menu,
  panels, notifications, lock, OSD) is one Quickshell process on Wayland
  layer-shell. SketchyBar plus Hammerspoon can imitate the bar and the menu
  tree. They cannot imitate the panels, the lock screen, or the OSD.
- AeroSpace has no groups, no scratchpad, no pin, no per-window opacity, and
  no runtime gap toggle. Those v4 keys have no port.

## Checklist (impact order)

- [x] **1. Theme sync is pointed at a dead layout.** DONE 2026-09-02. `bin/theme` pulls from
  `basecamp/omarchy` `master`. v4 lives at `omacom/omarchy` `quattro`, has
  22 themes (Solitude, Last Horizon, Lupine are new), a 24-colour
  `colors.toml`, and no `btop.theme` per theme: btop, ghostty, and the rest
  are generated from `default/themed/*.tpl`. Fix: repoint repo and ref,
  render btop from the template locally, sync the 3 new themes, and read the
  wallpapers from `backgrounds/` (now webp). Half a day.
- [x] **2. Web apps as app windows.** DONE 2026-09-02. v4 launches every web app with
  `--app=<url>` so it tiles as its own window. Ours open a Brave tab
  (HEY, Calendar, X, YouTube, Photos, Google Chat, Grok). Fix: `open -na
  "Brave Browser" --args --app=<url>` in aerospace.toml. One hour.
- [x] **3. Menu tree to v4 shape.** DONE 2026-09-02. v4 root: Apps, Learn, Trigger, Style,
  Setup, Install, Remove, Update, About, System, with nested search.
  Ours is a flat 10-item list. Fix: rebuild the Hammerspoon chooser from a
  nested table mirroring `default/omarchy/omarchy-menu.jsonc`, keep
  `cmd-alt-space` on it. Raycast stays on `cmd-space`. Half a day.
- [x] **4. Bar to v4 layout.** DONE 2026-09-02 (verify on the externals). v4: logo (opens menu) + workspaces on the
  left; indicators, clock, weather, update badge in the centre; tray,
  agents usage, bluetooth, network, audio, monitor, power on the right.
  Missing here: logo item, weather, caffeinate/DND/recording indicators,
  brew-outdated badge, Claude usage widget. Half a day for all five.
- [x] **5. Key gaps that do port.** DONE 2026-09-02 (no night light, no bar-toggle key, no cmd-tab; see report). `cmd-ctrl-e` emoji (Raycast emoji),
  `cmd-ctrl-r` reminders (Hammerspoon timer + notify), `cmd-ctrl-n` night
  light (Night Shift toggle), `cmd-ctrl-z` zoom (macOS accessibility zoom),
  `cmd-shift-space` hide/show bar (`sketchybar --bar hidden=toggle`),
  `cmd-ctrl-s` share menu (LocalSend is installed), `cmd-ctrl-q`
  calculator, `cmd-shift-ctrl-a` coding agent in a Ghostty window,
  `cmd-tab`/`cmd-shift-tab` next/prev workspace. Two hours.
- [x] **6. Screensaver.** DONE 2026-09-02. v4 runs `ttfx` ASCII art in a terminal per monitor
  after 150 s idle. Port: Hammerspoon idle timer opens Ghostty fullscreen
  per screen running `ttfx` on `~/.config/omarchy/branding/screensaver.txt`.
  Needs `ttfx` built from source (not in Homebrew). Half a day, medium risk.
- [x] **7. Shell aliases and functions.** DONE 2026-09-02. v4 `default/bash/` ships `ls`=eza,
  `ff` fzf, `n` nvim, tmux layout helpers, worktree helpers. Ours has
  starship only. Port the aliases to `zsh/zshrc`. One hour.
- [x] **8. Lock and idle timings.** CHECKED 2026-09-02: macOS lock is immediate after display off, stricter than v4; screensaver 150 s is ours; display sleep 10 min is the ceiling. v4: screensaver 150 s, lock 300 s. Set
  the same in macOS Lock Screen settings by hand. Ten minutes.
- [x] **9. Cheat sheet refresh.** DONE 2026-09-02 (12 rows added, all AeroSpace binds listed). `alt-k` table and the v4 hotkey page
  drifted. Regenerate the Hammerspoon table from aerospace.toml. One hour.
- [x] **10. Theme reaches Claude Code and Obsidian.** DONE 2026-09-02. `theme
  <name>` renders v4's `claude.json.tpl` into `~/.claude/themes/omarchy.json`
  (settings theme `custom:omarchy`, new sessions pick it up) and
  `obsidian.css.tpl` into an "Omarchy" theme in every vault Obsidian knows,
  selected in `appearance.json`.
- [ ] **11. Theme reaches tmux.** v4 pushes the palette into running tmux
  sessions. Half an hour. Only if tmux becomes daily.

## Not portable (do not attempt)

- Quickshell shell: control panels (audio, bluetooth, network, display,
  power, calendar), OSD, themed lock screen, notification centre, polkit.
  System Settings deep links stay the substitute.
- Hyprland dispatchers with no AeroSpace equivalent: groups, scratchpad,
  pop/pin, per-window opacity (`Super+Backspace`), gap toggle, window width
  save/restore, universal `Super+C/V/X` key injection.
- pacman updates, Snapper snapshots, dual-boot install, factory reset,
  crash diagnosis from systemd-coredump, plugin system (QML).
- Omarchy Chromium live theming: needs their Chromium micro-fork. Brave
  cannot take a theme colour from the command line.

## Running Omarchy itself on this Mac

- **Try Omarchy** (github.com/themartiano/try-omarchy) runs upstream v4 in a
  QEMU VM on Hypervisor.framework. Works on M4. Single window, no
  multi-monitor. Good as a reference for how v4 should feel.
- Bare metal needs Asahi Linux. The Asahi installer supports M1 and M2
  only. M4 has no timeline. Two external monitors do not work on any
  Apple Silicon Linux today. Not an option for this rig.
