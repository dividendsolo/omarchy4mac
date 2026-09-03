# Parity audit: omarchy-mac vs Omarchy v4.0.0

Audited 2026-08-17 against Omarchy v4.0.0 (released 2026-08-14): the full
`bin/` command surface (425 commands), the default keybindings
(`default/hypr/bindings/*.lua`), the menu system, and what each theme ships
(`themes/<name>/`). One flat checklist, ordered by impact. Checked = ported.
Unchecked = the roadmap, most valuable first. Items macOS already owns
natively (audio keys, brightness, notifications, dictation, emoji picker,
media keys) and items with no macOS meaning (installer ISO, Plymouth,
hibernation, hardware quirks, migrations) are deliberately absent — porting
them would duplicate the OS.

- [x] Tiling WM: focus/move/swap windows, 5 workspaces, move-to-workspace (silent variant included), workspace back-and-forth, monitor focus/move, resize, fullscreen modes, float toggle, close-all — AeroSpace (`aerospace/aerospace.toml`)
- [x] Top bar with workspaces + status — SketchyBar (`sketchybar/`)
- [x] Active-window borders — JankyBorders (`borders/`)
- [x] Every Omarchy theme, synced from the source repo (`theme --sync`), converted for Ghostty, Neovim/LazyVim, btop
- [x] Auto light/dark: instant re-theme on macOS appearance flip (native listener; Omarchy itself doesn't have this)
- [x] Theme chooser menu (⌘⌃⇧Space), system menu (⌘⌥Space), searchable keybindings overlay (⌥K)
- [x] Wallpaper cycling scoped to the active theme (⌘⌃P)
- [x] Time / weather / battery notices (⌘⌃⌥ T/W/B)
- [x] **One-command install** (DONE 2026-09-03: `install.sh` + `Brewfile`): `install.sh` that runs a Brewfile + creates all symlinks + first `theme --sync`. Omarchy's whole identity is install-and-done; this repo currently asks for ~10 manual steps. Biggest lever for anyone adopting it.
- [ ] **`omarchy4mac update`**: pull the repo, re-link, re-sync themes, restart services — the port's answer to `omarchy-update`. Keeps every adopter current with one command.
- [ ] **Theme backgrounds**: each Omarchy theme ships a `backgrounds/` dir; extend `theme --sync` to download them into `~/Pictures/Wallpapers` with the `<theme>_` prefix the wallpaper cycler already expects, and set the wallpaper on theme switch. Closes the single most visible gap in "the whole desktop changes".
- [ ] **Theme scope: more apps**: Omarchy themes carry tmux, lazygit, and vscode definitions; the upstream repo also themes alacritty/kitty. Add tmux + lazygit conversion to `theme` (both are in the daily toolkit; alacritty/kitty only if asked).
- [x] **Menu depth** (DONE 2026-09-03: v4 nested tree, see CHANGELOG): Omarchy's menu has apps / capture / toggle / system / theme / background submenus. The Hammerspoon menu covers system + theme + apps; add a Toggle submenu (bar on/off, borders on/off, gaps on/off, nightlight) and a Capture submenu that fronts macOS's own tools (⌘⇧5, color picker via Digital Color Meter).
- [ ] **Scratchpad** (SUPER+S in Omarchy): AeroSpace has no special workspace; emulate with a dedicated workspace + toggle binding, or a Hammerspoon window stash.
- [x] **Clipboard manager** (DONE 2026-09-03: ⌘⌃V fronts Raycast clipboard history) (SUPER+CTRL+V): front Raycast's clipboard history from the same binding so the muscle memory carries; document it rather than build one.
- [x] **Keybinding parity pass** (DONE 2026-09-03: v4 utility keys; bar toggle and gap toggle have no hook): map remaining v4 bindings that have macOS equivalents — universal ⌘K keybindings key (match Omarchy's SUPER+K on ⌘K or keep ⌥K, decide once), window width save/restore, toggle gaps, toggle bar (⌘⇧Space in Omarchy), calculator key. Update the overlay as each lands.
- [x] **Webapp launchers** (DONE 2026-09-03: Brave app windows on the v4 keys): Omarchy binds ~12 sites as chromeless web apps (SUPER+SHIFT+letter). Port as `open -na "Google Chrome" --args --app=URL` bindings in Hammerspoon, user-configurable list.
- [ ] **OCR / capture-text** (SUPER+CTRL+PRINT): screenshot region → Vision framework text extraction → clipboard, as a small script; macOS has Live Text but no one-key flow.
- [ ] **Nightlight toggle**: menu item + binding driving Night Shift via `nightlight` CLI or osascript.
- [x] **Idle-lock toggle** (DONE 2026-09-03: ⌘⌃I caffeinate with bar indicator) (Omarchy's SUPER+CTRL+I): `caffeinate` wrapper with a bar indicator so "keep awake" is visible.
- [x] **App launcher** (decided: Raycast is the stand-in, ⌘Space bound): Omarchy uses walker; the port leans on Raycast/Spotlight. Decision recorded: do not build a launcher — document Raycast as the blessed stand-in and ship the ⌘Space binding it already has. Revisit only if adopters push.
- [x] **Screensaver / lock aesthetic** (DONE 2026-09-03: ttfx screensaver; lock screen stays macOS): Omarchy ships branded lock/screensaver art per theme (`preview-unlock.png`, `shell.lock.toml`). Lowest impact; macOS lock screen is fine. Park unless it becomes fun.
