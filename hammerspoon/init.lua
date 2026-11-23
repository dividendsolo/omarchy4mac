require("hs.ipc")

local BREW_PATH = "/opt/homebrew/bin:/usr/local/bin"
local function withBrew(cmd) return "export PATH=" .. BREW_PATH .. ":$PATH; " .. cmd end

local bindings = {
  { "SUPER + SPACE",            "Raycast" },
  { "ALT + SPACE",              "Dictation on / off (Hex)" },
  { "hold RIGHT ALT",           "Dictate while held (Hex)" },
  { "ALT + RETURN",             "Ghostty (terminal) in the focused folder" },
  { "SUPER + ALT + RETURN",     "Ghostty + tmux (Work)" },
  { "SUPER + CTRL + RETURN",    "Ghostty + herdr" },
  { "SUPER + SHIFT + RETURN",   "Browser (macOS default)" },
  { "SUPER + SHIFT + ALT + B",  "Browser (private window)" },
  { "SUPER + ALT + C",          "Chrome" },
  { "SUPER + SHIFT + F",        "Finder" },
  { "SUPER + SHIFT + ALT + F",  "Finder" },
  { "SUPER + SHIFT + N",        "Ghostty + nvim" },
  { "SUPER + SHIFT + D",        "Ghostty + lazydocker" },
  { "SUPER + SHIFT + M",        "Spotify" },
  { "SUPER + SHIFT + Q",        "Calculator" },
  { "SUPER + SHIFT + A",        "Claude" },
  { "SUPER + SHIFT + ALT + A",  "Grok (app window)" },
  { "SUPER + SHIFT + O",        "Obsidian" },
  { "SUPER + SHIFT + W",        "Typora" },
  { "SUPER + SHIFT + G",        "Signal" },
  { "SUPER + SHIFT + ALT + G",  "WhatsApp" },
  { "SUPER + SHIFT + CTRL + G", "Google Chat (app window)" },
  { "SUPER + SHIFT + P",        "Google Photos (app window)" },
  { "SUPER + SHIFT + X",        "X" },
  { "SUPER + SHIFT + ALT + X",  "X: new post" },
  { "SUPER + SHIFT + Y",        "YouTube (app window)" },
  { "SUPER + SHIFT + /",        "1Password" },
  { "ALT + SHIFT + L",          "Copy the browser tab's URL" },
  { "SUPER + SHIFT + C",        "HEY Calendar (app window)" },
  { "SUPER + SHIFT + E",        "HEY Mail (app window)" },

  { "ALT + W",                  "Quit app (sends ⌘Q)" },
  { "ALT + Q",                  "Quit app (sends ⌘Q)" },
  { "CTRL + ALT + BACKSPACE",   "Close all windows but current" },
  { "ALT + S",                  "Toggle floating / tiling" },
  { "ALT + A",                  "Toggle accordion / tiles (workspace)" },
  { "ALT + L",                  "Cycle workspace: tiles / accordion / floating" },
  { "SUPER + ALT + L",          "Cycle workspace layout back" },
  { "ALT + M",                  "Minimize window (to the Dock)" },
  { "ALT + J",                  "Toggle tiles horizontal / vertical" },
  { "ALT + F",                  "Fullscreen (tile)" },
  { "SUPER + ALT + F",          "Fullscreen (tile)" },
  { "SUPER + CTRL + F",         "Fullscreen (tile)" },

  { "SUPER + LEFT / DOWN / UP / RIGHT",  "Focus window in direction (crosses displays)" },
  { "SUPER + `",                "Quake console (default agent)" },
  { "SUPER + SHIFT + `",        "Second Quake console" },
  { "SUPER + ALT + `",          "Cycle next window in workspace" },
  { "SUPER + ALT + SHIFT + `",  "Cycle prev window in workspace" },
  { "CTRL + ALT + TAB",         "Focus next monitor" },
  { "CTRL + ALT + SHIFT + TAB", "Focus prev monitor" },

  { "SUPER + SHIFT + ←/↓/↑/→",  "Swap window in direction" },

  { "ALT + 1..5",               "Switch to this monitor's workspace N" },
  { "SUPER + SHIFT + 1..5",     "Move window to this monitor's workspace N and follow" },
  { "SUPER + SHIFT + ALT + 1..5", "Move window to this monitor's workspace N (stay)" },
  { "ALT + TAB",                "Next workspace on this monitor" },
  { "SUPER + CTRL + TAB",       "Back-and-forth between workspaces" },
  { "SUPER + SHIFT + ALT + ←/→/↑/↓", "Move workspace to prev/next monitor" },
  { "SUPER + CTRL + SHIFT + ←/↓/↑/→", "Move focused window across monitors (floats centre)" },

  { "ALT + =",                  "Grow focused window" },
  { "ALT + -",                  "Shrink focused window" },
  { "SUPER + SHIFT + =",        "Grow height" },
  { "SUPER + SHIFT + -",        "Shrink height" },

  { "SUPER + CTRL + A",         "Sound settings" },
  { "SUPER + CTRL + B",         "Bluetooth settings" },
  { "SUPER + CTRL + N",         "Network (Wi-Fi settings)" },
  { "SUPER + CTRL + S",         "Share (LocalSend)" },
  { "SUPER + CTRL + E",         "Emoji picker" },
  { "SUPER + CTRL + SHIFT + Q", "Quit every Dock app (keeps Finder)" },
  { "SUPER + CTRL + R",         "Set a reminder (20m message)" },
  { "SUPER + CTRL + Z",         "Zoom (macOS accessibility)" },
  { "SUPER + SHIFT + CTRL + A", "Coding agent (default: Setup > Defaults > Agent)" },
  { "ALT + SHIFT + T",          "Activity (Ghostty + btop)" },
  { "SUPER + CTRL + ALT + E",   "World clock (Clock)" },
  { "SUPER + CTRL + ALT + F",   "Full screen desktop (hide or show the bar)" },
  { "SUPER + CTRL + H",         "System Information" },
  { "SUPER + CTRL + .",         "HandBrake (transcoding)" },
  { "SUPER + CTRL + L",         "Lock screen" },
  { "SUPER + CTRL + I",         "Toggle caffeinate" },
  { "ALT + ,",                  "Open the newest notification" },
  { "SUPER + CTRL + ALT + ,",   "Toggle Do Not Disturb" },
  { "SUPER + CTRL + C",         "Screenshot picker" },
  { "SUPER + CTRL + ALT + C",   "Screenshot (region)" },
  { "SUPER + CTRL + V",         "Raycast clipboard history" },
  { "SUPER + CTRL + P",         "Cycle wallpaper (~/Pictures/Wallpapers)" },
  { "SUPER + CTRL + W",         "Next background (cycle wallpaper)" },
  { "SUPER + CTRL + G",         "Gaming mode (quit all Dock apps, launch Steam)" },
  { "SUPER + CTRL + ALT + T",   "Date & time toast" },
  { "SUPER + CTRL + ALT + W",   "Weather toast" },
  { "SUPER + CTRL + ALT + B",   "Battery toast" },
  { "SUPER + ESC",              "System menu (Lock/Sleep/Restart/…)" },

  { "SUPER + ALT + SPACE",      "Apps launcher (curated)" },
  { "SUPER + SHIFT + SPACE",    "Omarchy control menu" },
  { "SUPER + CTRL + SHIFT + SPACE", "Theme chooser" },
  { "SUPER + CTRL + T",         "Theme chooser" },
  { "OPT + T",                  "Random theme (matches system light/dark)" },

  { "SUPER + SHIFT + ;",        "Enter service mode (R=flatten, F=float, esc=exit)" },

  { "ALT + K",                  "Show this keybindings overlay" },
}

local function hex(s)
  return { hex = s }
end

local COLORS = {
  bg       = hex("#1a1b26"),
  fg       = hex("#c0caf5"),
  blue     = hex("#7aa2f7"),
  magenta  = hex("#bb9af7"),
  comment  = hex("#565f89"),
}

local function closeIfOpen(chooser)
  if chooser and chooser:isVisible() then chooser:hide(); return true end
end

local keysChooser
local function showKeybindings()
  if closeIfOpen(keysChooser) then return end
  if not keysChooser then
    local choices = {}
    for _, b in ipairs(bindings) do
      table.insert(choices, {
        text    = b[1],
        subText = b[2],
      })
    end
    keysChooser = hs.chooser.new(function(_) end)
    keysChooser:choices(choices)
    keysChooser:searchSubText(true)
    keysChooser:width(35)
    keysChooser:rows(12)
    keysChooser:bgDark(true)
    keysChooser:fgColor(COLORS.blue)
    keysChooser:subTextColor(COLORS.fg)
    keysChooser:placeholderText("Filter keybindings…")
  end
  keysChooser:show()
end

hs.hotkey.bind({"alt"}, "k", showKeybindings)

local function notifyFromScript(script)
  hs.task.new("/bin/bash", function(_, stdOut, _)
    local title, body = stdOut:match("^(.-)|||(.-)\n?$")
    if title then
      hs.notify.new({ title = title, informativeText = body, withdrawAfter = 5 }):send()
    end
  end, { "-lc", script }):start()
end

hs.hotkey.bind({"cmd", "ctrl", "alt"}, "t", function() notifyFromScript("~/.local/bin/omarchy-notice time")    end)
hs.hotkey.bind({"cmd", "ctrl", "alt"}, "w", function() notifyFromScript("~/.local/bin/omarchy-notice weather") end)
hs.hotkey.bind({"cmd", "ctrl", "alt"}, "b", function() notifyFromScript("~/.local/bin/omarchy-notice battery") end)
hs.hotkey.bind({"cmd", "ctrl"},        "p", function() notifyFromScript("~/.local/bin/omarchy-cycle-wallpaper") end)
hs.hotkey.bind({"cmd", "ctrl"},        "w", function() notifyFromScript("~/.local/bin/omarchy-cycle-wallpaper") end)
hs.hotkey.bind({"cmd", "ctrl"},        "g", function() notifyFromScript("~/.local/bin/gaming-mode") end)
hs.hotkey.bind({"alt", "shift"}, "l", function()
  local front = hs.application.frontmostApplication()
  local id = ((front and front:bundleID()) or ""):gsub("[^%w%.%-]", "")
  notifyFromScript("~/.local/bin/omarchy-copy-url '" .. id .. "'")
end)
hs.hotkey.bind({"cmd", "ctrl", "shift"}, "q", function()
  hs.alert.show("Quitting all apps")
  hs.task.new("/bin/bash", nil, { "-lc", "~/.local/bin/quit-all" }):start()
end)

local function bindDictation()
  local hex = "/Applications/Hex.app/Contents/MacOS/hex"
  hs.hotkey.bind({"alt"}, "space", function() hs.task.new(hex, nil, { "dictation", "toggle" }):start() end)
end
bindDictation()

local reminders = {}
local function setReminder()
  local button, text = hs.dialog.textPrompt("Reminder", "Delay then message, e.g. 20m stand up", "", "Set", "Cancel")
  if button ~= "Set" or text == "" then return end
  local delay, message = text:match("^%s*([%dhms%. ]+)%s+(.+)$")
  if not delay then hs.alert.show("Format: 20m message"); return end
  local seconds = 0
  for n, unit in delay:gmatch("([%d%.]+)%s*([hms]?)") do
    local v = tonumber(n) or 0
    seconds = seconds + (unit == "h" and v * 3600 or unit == "s" and v or v * 60)
  end
  if seconds <= 0 then hs.alert.show("Format: 20m message"); return end
  table.insert(reminders, hs.timer.doAfter(seconds, function()
    hs.notify.new({ title = "Reminder", informativeText = message, withdrawAfter = 0 }):send()
    hs.sound.getByName("Glass"):play()
  end))
  hs.alert.show("Reminder in " .. delay:gsub("^%s+", ""):gsub("%s+$", "") .. ": " .. message)
end
hs.hotkey.bind({"cmd", "ctrl"}, "r", setReminder)

local function newestNotification(root)
  local queue, i = { root }, 1
  while queue[i] do
    local el = queue[i]; i = i + 1
    local sub = el:attributeValue("AXSubrole") or ""
    if sub == "AXNotificationCenterBanner" or sub == "AXNotificationCenterAlert" then return el end
    for _, child in ipairs(el:attributeValue("AXChildren") or {}) do queue[#queue + 1] = child end
  end
end
hs.hotkey.bind({"alt"}, ",", function()
  local nc = hs.application.get("com.apple.notificationcenterui")
  local banner = nc and newestNotification(hs.axuielement.applicationElement(nc))
  if banner then banner:performAction("AXPress") end
end)

local SCREENSAVER_IDLE = 150
local screensaverTap = nil
local screensaverRunning = false

local function stopScreensaver()
  if screensaverTap then screensaverTap:stop(); screensaverTap = nil end
  if not screensaverRunning then return end
  screensaverRunning = false
  hs.execute("pkill -f '[o]marchy-screensaver$'; pkill -x ttfx", true)
end

local function startScreensaver(force)
  if screensaverRunning then return end
  local ok = os.execute("~/.local/bin/omarchy-launch-screensaver " .. (force and "force" or ""))
  if not ok then return end
  screensaverRunning = true
  hs.timer.doAfter(1.5, function()
    if not screensaverRunning then return end
    screensaverTap = hs.eventtap.new({
      hs.eventtap.event.types.keyDown, hs.eventtap.event.types.mouseMoved,
      hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.rightMouseDown,
      hs.eventtap.event.types.scrollWheel,
    }, function() stopScreensaver(); return false end)
    screensaverTap:start()
  end)
end
launchScreensaver = startScreensaver

hs.timer.doEvery(15, function()
  if screensaverRunning then
    if hs.execute("pgrep -f '[o]marchy-screensaver$'", true) == "" then stopScreensaver() end
    return
  end
  if hs.host.idleTime() >= SCREENSAVER_IDLE then startScreensaver(false) end
end)

hs.task.new("/bin/bash", nil, { "-lc", "~/.local/bin/omarchy-bg-set --login " .. tostring(hs.processInfo.processID) }):start()

local reapplyTimer = nil
bgScreenWatcher = hs.screen.watcher.new(function()
  if reapplyTimer then reapplyTimer:stop() end
  reapplyTimer = hs.timer.doAfter(2, function() hs.task.new("/bin/bash", nil, { "-lc", "~/.local/bin/omarchy-bg-set --reapply" }):start() end)
end):start()

local showAppsMenu, showThemeChooser, showOmarchyMenu, reloadIfWhole

local function sh(cmd) return function() hs.execute(withBrew(cmd), true) end end
local function app(name) return function() hs.application.launchOrFocus(name) end end
local function url(u) return sh("open '" .. u .. "'") end
local function settings(pane) return sh([[open "x-apple.systempreferences:]] .. pane .. [["]]) end
local function ghostty(cmd) return sh([[open -na Ghostty --args -e "$HOME/.local/bin/omarchy-tui" sh -c ']] .. cmd .. [[']]) end
local function nvimEdit(path) return sh([[open -na Ghostty --args -e nvim "]] .. path .. [["]]) end
local function keystroke(code, mods)
  return sh([[osascript -e 'tell application "System Events" to key code ]] .. code .. [[ using {]] .. mods .. [[}']])
end
local function toast(scriptName) return function() notifyFromScript("~/.local/bin/" .. scriptName) end end
local APPEARANCE = os.getenv("HOME") .. "/.local/bin/omarchy-appearance"
local function look(what, value, text, sub)
  return { text = text, action = function() hs.alert.show((hs.execute(APPEARANCE .. " " .. what .. " " .. value):gsub("%s+$", "")), 4) end,
    sub = function() return (hs.execute(APPEARANCE .. " " .. what):gsub("%s+$", "") == value and "✓ " or "") .. sub end }
end
local function webapp(u) return sh("~/.local/bin/omarchy-launch-browser --app=" .. u) end
local MICROSOFT = {
  { text = "Outlook",    sub = "Microsoft 365 web app", action = webapp("https://outlook.cloud.microsoft/mail/") },
  { text = "Word",       sub = "Microsoft 365 web app", action = webapp("https://word.cloud.microsoft/") },
  { text = "Excel",      sub = "Microsoft 365 web app", action = webapp("https://excel.cloud.microsoft/") },
  { text = "PowerPoint", sub = "Microsoft 365 web app", action = webapp("https://powerpoint.cloud.microsoft/") },
  { text = "Teams",      sub = "Microsoft 365 web app", action = webapp("https://teams.cloud.microsoft/") },
  { text = "OneDrive",   sub = "Microsoft 365 web app", action = webapp("https://onedrive.cloud.microsoft/") },
}
local D = (function()
  local target = hs.execute("readlink " .. os.getenv("HOME") .. "/.hammerspoon/init.lua"):gsub("%s+$", "")
  if target == "" then target = os.getenv("HOME") .. "/.hammerspoon/init.lua" end
  return target:match("^(.*)/hammerspoon/[^/]+$") or (os.getenv("HOME") .. "/code/omarchy4mac")
end)()
local ZSH = hs.fs.attributes(D .. "/zsh/omarchy.zsh") and (D .. "/zsh/omarchy.zsh") or (D .. "/zsh/zshrc")

local MENU = {
  { text = "Apps", sub = "Launch an app", action = function() showAppsMenu() end },
  { text = "Learn", sub = "Manuals and cheat sheets", children = {
    { text = "Keybindings", sub = "This desktop (alt-k)", action = function() showKeybindings() end },
    { text = "Omarchy manual", sub = "omarchy.org/manual", action = url("https://omarchy.org/manual/") },
    { text = "Omarchy hotkeys", sub = "The upstream table", action = url("https://omarchy.org/manual/hotkeys/") },
    { text = "AeroSpace guide", sub = "Window manager docs", action = url("https://nikitabobko.github.io/AeroSpace/guide") },
    { text = "Neovim", sub = "LazyVim keymaps", action = url("https://www.lazyvim.org/keymaps") },
    { text = "Tmux", sub = "Cheat sheet", action = url("https://tmuxcheatsheet.com") },
    { text = "Herdr", sub = "Keybindings", action = url("https://herdr.dev/docs/") },
  }},
  { text = "Appearance", sub = "Theme, background, windows, dock", children = {
    { text = "Theme", sub = "Pick a theme", action = function() showThemeChooser() end },
    { text = "Background", sub = "Next image or video for this theme", action = toast("omarchy-cycle-wallpaper") },
    { text = "Font", sub = "Terminal font (Ghostty config)", action = nvimEdit(os.getenv("HOME") .. "/Library/Application Support/com.mitchellh.ghostty/config") },
    { text = "Menu Bar", sub = "SketchyBar and the macOS menu bar", children = {
      { text = "Hide or Show", sub = "Hide or show SketchyBar", action = sh("sketchybar --bar hidden=toggle") },
      { text = "Config", sub = "Edit sketchybarrc", action = nvimEdit(D .. "/sketchybar/sketchybarrc") },
      { text = "macOS Menu Bar", sub = "Control Center settings", action = settings("com.apple.ControlCenter-Settings.extension") },
    }},
    { text = "Windows", sub = "Gaps and borders", children = {
      { text = "Gaps", sub = "Edit [gaps] in aerospace.toml", action = nvimEdit(D .. "/aerospace/aerospace.toml") },
      { text = "Borders", sub = "Edit bordersrc (width, colour, corners)", action = nvimEdit(D .. "/borders/bordersrc") },
    }},
    { text = "Window Transparency", sub = "Terminal and bar", children = {
      look("transparency", "opaque", "Opaque Windows", "Solid terminal and bar"),
      look("transparency", "transparent", "Transparent Windows", "See-through terminal (default)"),
      look("transparency", "glassy", "Glassy Windows", "Frosted terminal and bar"),
    }},
    { text = "Window Corners", sub = "Window borders", children = {
      look("corners", "theme", "Theme Corners", "The default round border"),
      look("corners", "sharp", "Sharp Corners", "Square borders"),
      look("corners", "rounded", "Rounded Corners", "Round borders"),
    }},
    { text = "Branding", sub = "Screensaver and About", children = {
      { text = "Screensaver", sub = "Edit the ASCII art", action = nvimEdit(os.getenv("HOME") .. "/.config/omarchy/branding/screensaver.txt") },
      { text = "About", sub = "fastfetch", action = ghostty("fastfetch") },
    }},
    { text = "Dock", sub = "Desktop & Dock settings", action = settings("com.apple.Desktop-Settings.extension") },
    { text = "Workspace Layout", sub = "AeroSpace layout of this workspace", children = {
      { text = "Tiles / Accordion", sub = "alt-a", action = sh("aerospace layout accordion tiles") },
      { text = "Split Direction", sub = "alt-j", action = sh("aerospace layout tiles horizontal vertical") },
      { text = "Float / Tile", sub = "alt-s", action = sh("aerospace layout floating tiling") },
    }},
    { text = "Animations", sub = "Theme intros and reduce motion", children = {
      { text = "Theme Intros", sub = "Play or skip a theme's intro video", action = toast("omarchy-toggle-intros") },
      { text = "Reduce Motion", sub = "Accessibility > Display (also skips intros)", action = settings("com.apple.Accessibility-Settings.extension") },
    }},
    { text = "Unlock", sub = "Lock Screen settings", action = settings("com.apple.Lock-Screen-Settings.extension") },
    { text = "Light / Dark", sub = "macOS appearance", action = settings("com.apple.Appearance-Settings.extension") },
    { text = "Random Theme", sub = "Shuffle within light/dark", action = sh("~/.local/bin/theme random") },
    { text = "Sync Themes", sub = "Pull Omarchy 4 themes", action = ghostty("~/.local/bin/theme --sync") },
  }},
  { text = "Trigger", sub = "Do a thing now", children = {
    { text = "Emoji", sub = "Raycast emoji picker", action = url("raycast://extensions/raycast/emoji-symbols/search-emoji-symbols") },
    { text = "Capture", sub = "Screenshot / record / colour", children = {
      { text = "Screenshot", sub = "macOS capture picker", action = keystroke(23, "command down, shift down") },
      { text = "Screenrecord", sub = "Same picker, choose Record", action = keystroke(23, "command down, shift down") },
      { text = "Color", sub = "Digital Color Meter", action = app("Digital Color Meter") },
    }},
    { text = "Share", sub = "LocalSend", children = {
      { text = "Send", sub = "Open LocalSend", action = app("LocalSend") },
      { text = "Receive", sub = "Open LocalSend", action = app("LocalSend") },
    }},
    { text = "Toggle", sub = "Switch something on or off", children = {
      { text = "Stay Awake", sub = "caffeinate on/off", action = sh([[pgrep -x caffeinate >/dev/null && pkill -x caffeinate || (caffeinate -dimsu &)]]) },
      { text = "Notifications", sub = "Do Not Disturb", action = sh([[shortcuts run "Toggle Do Not Disturb"]]) },
      { text = "Menu Bar", sub = "Hide or show SketchyBar", action = sh("sketchybar --bar hidden=toggle") },
      { text = "Gaming Mode", sub = "Quit apps, Tailscale down, Steam", action = toast("gaming-mode") },
      { text = "Quit All", sub = "Quit every Dock app, keep Finder", action = sh("~/.local/bin/quit-all") },
      { text = "Screensaver", sub = "Enable or disable the idle screensaver", action = toast("omarchy-toggle-screensaver") },
      { text = "Herdr Theme Sync", action = function()
          local on = hs.fs.attributes(os.getenv("HOME") .. "/.config/theme-switcher/herdr-sync")
          hs.alert.show((hs.execute("~/.local/bin/theme --herdr-sync " .. (on and "off" or "on")):gsub("%s+$", "")), 3)
        end,
        sub = function()
          return (hs.fs.attributes(os.getenv("HOME") .. "/.config/theme-switcher/herdr-sync") and "✓ " or "")
            .. "Mirror theme switches to your herdr machines"
        end },
    }},
    { text = "Transcode", sub = "HandBrake", action = app("HandBrake") },
    { text = "Speed Test", sub = "Network (Cloudflare)", action = url("https://speed.cloudflare.com") },
    { text = "Reminder", sub = "20m message", action = function() setReminder() end },
    { text = "Notice", sub = "Time / weather / battery toast", children = {
      { text = "Time", sub = "Date and time", action = toast("omarchy-notice time") },
      { text = "Weather", sub = "wttr.in", action = toast("omarchy-notice weather") },
      { text = "Battery", sub = "Charge and source", action = toast("omarchy-notice battery") },
    }},
  }},
  { text = "Setup", sub = "Configure the desktop", children = {
    { text = "Defaults", sub = "Default apps", children = {
      { text = "Agent", sub = "Default coding agent (Super+Shift+Ctrl+A)", children = {
        { text = "Claude Code", sub = "claude", action = toast("omarchy-default-agent claude") },
        { text = "Codex", sub = "codex", action = toast("omarchy-default-agent codex") },
        { text = "Grok", sub = "grok", action = toast("omarchy-default-agent grok") },
        { text = "Hermes", sub = "hermes", action = toast("omarchy-default-agent hermes") },
        { text = "OpenClaw", sub = "openclaw", action = toast("omarchy-default-agent openclaw") },
      }},
    }},
    { text = "Monitors", sub = "Displays", action = settings("com.apple.Displays-Settings.extension") },
    { text = "Keybindings", sub = "Edit aerospace.toml", action = nvimEdit(D .. "/aerospace/aerospace.toml") },
    { text = "Input", sub = "Keyboard", action = settings("com.apple.Keyboard-Settings.extension") },
    { text = "Network", sub = "Wi-Fi", action = settings("com.apple.wifi-settings-extension") },
    { text = "Bluetooth", sub = "Devices", action = settings("com.apple.BluetoothSettings") },
    { text = "Audio", sub = "Sound", action = settings("com.apple.Sound-Settings.extension") },
    { text = "Security", sub = "Privacy & Security", action = settings("com.apple.settings.PrivacySecurity.extension") },
    { text = "Sharing", sub = "Sharing settings", action = settings("com.apple.preferences.sharing") },
    { text = "Config", sub = "Edit a config file", children = {
      { text = "AeroSpace", sub = "aerospace.toml", action = nvimEdit(D .. "/aerospace/aerospace.toml") },
      { text = "SketchyBar", sub = "sketchybarrc", action = nvimEdit(D .. "/sketchybar/sketchybarrc") },
      { text = "Hammerspoon", sub = "init.lua", action = nvimEdit(D .. "/hammerspoon/init.lua") },
      { text = "Ghostty", sub = "Application Support config", action = nvimEdit(os.getenv("HOME") .. "/Library/Application Support/com.mitchellh.ghostty/config") },
      { text = "Zsh", sub = "shell defaults", action = nvimEdit(ZSH) },
      { text = "Starship", sub = "starship.toml", action = nvimEdit(D .. "/starship/starship.toml") },
    }},
  }},
  { text = "Install", sub = "Add software", children = {
    { text = "Package", sub = "brew search in Ghostty", action = ghostty("read -p \"brew search: \" q && brew search \"$q\"") },
    { text = "Homebrew", sub = "brew.sh", action = url("https://brew.sh") },
    { text = "Omarchy themes", sub = "Community themes", action = url("https://omarchy.org/themes/") },
    { text = "Service", sub = "Apps and web services", children = {
      { text = "Microsoft", sub = "Outlook, Word, Excel, PowerPoint, Teams, OneDrive", children = MICROSOFT },
      { text = "Slack", sub = "brew install --cask slack",
        present = function() return hs.application.pathForBundleID("com.tinyspeck.slackmacgap") ~= nil end,
        action = function()
          if not hs.application.launchOrFocus("Slack") then ghostty("brew install --cask slack && open -a Slack")() end
        end },
    }},
  }},
  { text = "Remove", sub = "Remove software", children = {
    { text = "Package", sub = "brew uninstall in Ghostty", action = ghostty("brew list --cask; brew list --formula | column; read -p \"brew uninstall: \" q && brew uninstall \"$q\"") },
  }},
  { text = "Update", sub = "Update software and configs", children = {
    { text = "Homebrew", sub = "brew update && upgrade", action = ghostty("brew update && brew upgrade") },
    { text = "macOS", sub = "Software Update", action = settings("com.apple.Software-Update-Settings.extension") },
    { text = "Themes", sub = "theme --sync", action = ghostty("~/.local/bin/theme --sync") },
    { text = "Config", sub = "Reload a service", children = {
      { text = "AeroSpace", sub = "reload-config", action = sh("aerospace reload-config") },
      { text = "SketchyBar", sub = "--reload", action = sh("sketchybar --reload") },
      { text = "Hammerspoon", sub = "hs.reload()", action = function() reloadIfWhole() end },
      { text = "Borders", sub = "brew services restart", action = sh("brew services restart borders") },
    }},
  }},
  { text = "About", sub = "fastfetch", action = ghostty("fastfetch") },
  { text = "System", sub = "Lock, sleep, restart, shut down", children = {
    { text = "Screensaver", sub = "Start it now", action = function() launchScreensaver(true) end },
    { text = "Lock", sub = "Lock screen", action = keystroke(12, "control down, command down") },
    { text = "Sleep", sub = "pmset sleepnow", action = sh("pmset sleepnow") },
    { text = "Restart", sub = "Restart the Mac", action = sh([[osascript -e 'tell application "System Events" to restart']]) },
    { text = "Shut Down", sub = "Shut down the Mac", action = sh([[osascript -e 'tell application "System Events" to shut down']]) },
    { text = "Log Out", sub = "Log out", action = sh([[osascript -e 'tell application "System Events" to log out']]) },
  }},
}

local function flatten(items, path, out)
  for _, item in ipairs(items) do
    local here = path and (path .. " › " .. item.text) or item.text
    if item.children then flatten(item.children, here, out)
    else table.insert(out, { item = item, path = here, action = item.action }) end
  end
  return out
end

local function rowText(item)
  local installed = item.present and item.present()
  return hs.styledtext.new(item.text, { color = installed and COLORS.comment or COLORS.blue, font = { size = 20 } }), installed
end

local menuChooser
local function showMenuLevel(items, parents)
  parents = parents or {}
  local level = {}
  if #parents > 0 then table.insert(level, { text = (rowText({ text = "‹ Back" })), subText = parents[#parents].text, back = true }) end
  for i, item in ipairs(items) do
    local text, installed = rowText(item)
    local sub = type(item.sub) == "function" and item.sub() or item.sub
    table.insert(level, { text = text, subText = installed and "✓ installed" or sub or "", idx = i })
  end
  local leaves = flatten(items, nil, {})
  local leafRows = {}
  for i, leaf in ipairs(leaves) do
    leafRows[i] = { text = rowText(leaf.item), subText = leaf.path, leaf = i, name = leaf.item.text }
  end

  menuChooser = hs.chooser.new(function(choice)
    if not choice then return end
    if choice.back then
      local up = {}
      for i = 1, #parents - 1 do up[i] = parents[i] end
      local parentItems = (#parents > 1) and parents[#parents - 1].item.children or MENU
      return showMenuLevel(parentItems, up)
    end
    if choice.leaf then return leaves[choice.leaf].action() end
    local item = items[choice.idx]
    if item.children then
      local down = {}
      for i, p in ipairs(parents) do down[i] = p end
      table.insert(down, { text = item.text, item = item })
      return showMenuLevel(item.children, down)
    end
    if item.action then item.action() end
  end)
  menuChooser:queryChangedCallback(function(query)
    if query == "" then menuChooser:choices(level); return end
    local q = query:lower()
    local hits = {}
    for _, row in ipairs(leafRows) do
      if (row.name .. " " .. row.subText):lower():find(q, 1, true) then table.insert(hits, row) end
    end
    menuChooser:choices(hits)
  end)
  menuChooser:choices(level)
  menuChooser:width(28)
  menuChooser:rows(#level)
  menuChooser:bgDark(true)
  menuChooser:subTextColor(COLORS.fg)
  local crumbs = ""
  for _, p in ipairs(parents) do crumbs = crumbs .. p.text .. " › " end
  menuChooser:placeholderText(crumbs == "" and "Omarchy…" or crumbs)
  menuChooser:show()
end

showOmarchyMenu = function(section)
  if closeIfOpen(menuChooser) then return end
  if section then
    for _, item in ipairs(MENU) do
      if item.text == section and item.children then
        return showMenuLevel(item.children, { { text = item.text, item = item } })
      end
    end
  end
  showMenuLevel(MENU)
end
omarchyMenu = showOmarchyMenu

reloadIfWhole = function()
  local path = os.getenv("HOME") .. "/.hammerspoon/init.lua"
  local f = io.open(path, "r")
  local text = f and f:read("*a") or ""
  if f then f:close() end
  if text:find("omarchyMenu = showOmarchyMenu", 1, true) and load(text) then return hs.reload() end
  hs.alert.show("init.lua is not whole yet: kept the running menu", 4)
end

hs.hotkey.bind({"cmd", "shift"}, "space", function() showOmarchyMenu() end)

local themeChooser
showThemeChooser = function(selectRow)
  if closeIfOpen(themeChooser) then return end
  local cache = os.getenv("HOME") .. "/.config/theme-switcher/cache"
  local themes = {}
  local handle = io.popen("ls -1 " .. cache .. " 2>/dev/null | sort")
  if handle then
    for line in handle:lines() do table.insert(themes, line) end
    handle:close()
  end
  if #themes == 0 then
    hs.notify.new({title="Theme", informativeText="No themes cached. Run: theme --sync", withdrawAfter=5}):send()
    return
  end

  local current = ""
  local f = io.open(os.getenv("HOME") .. "/.config/theme-switcher/current", "r")
  if f then current = f:read("*line") or ""; f:close() end

  local choices = {}
  for _, name in ipairs(themes) do
    table.insert(choices, {
      text = name,
      subText = (name == current) and "● current" or "",
      themeName = name,
    })
  end

  themeChooser = hs.chooser.new(function(choice)
    if choice then
      hs.task.new("/bin/bash", function()
        hs.notify.new({title="Theme", informativeText="Switched to " .. choice.themeName, withdrawAfter=3}):send()
      end, { "-lc", '~/.local/bin/theme "$1"', "theme", choice.themeName }):start()
    end
  end)

  local delKey = hs.hotkey.new({"cmd"}, "delete", function()
    local row = themeChooser:selectedRowContents()
    if not row or not row.themeName then return end
    if row.themeName == current then
      hs.alert.show(row.themeName .. " is the current theme. Switch to another theme first.", 3)
      return
    end
    local index = themeChooser:selectedRow()
    themeChooser:hide()
    local button = hs.dialog.blockAlert("Delete the " .. row.themeName .. " theme?",
      "Theme Sync will not bring it back.", "Delete", "Cancel", "warning")
    if button ~= "Delete" then return showThemeChooser(index) end
    hs.task.new(os.getenv("HOME") .. "/.local/bin/theme", function(code, _, err)
      if code ~= 0 then hs.alert.show("Could not delete " .. row.themeName .. ": " .. (err or ""), 4) end
      showThemeChooser(math.max(index - 1, 1))
    end, { "--remove", row.themeName }):start()
  end)
  themeChooser:showCallback(function() delKey:enable() end)
  themeChooser:hideCallback(function() delKey:delete() end)

  themeChooser:choices(choices)
  themeChooser:width(20)
  themeChooser:rows(10)
  themeChooser:bgDark(true)
  themeChooser:fgColor(COLORS.blue)
  themeChooser:subTextColor(COLORS.fg)
  themeChooser:placeholderText("Pick a theme… (⌘⌫ deletes)")
  themeChooser:show()
  if selectRow then themeChooser:selectedRow(math.min(selectRow, #choices)) end
end

hs.hotkey.bind({"cmd", "ctrl", "shift"}, "space", showThemeChooser)
hs.hotkey.bind({"cmd", "ctrl"}, "t", showThemeChooser)
hs.hotkey.bind({"cmd", "alt"}, "space", function() showAppsMenu() end)

local apps = {
  { name = "1Password",        sub = "Passwords",         action = function() hs.application.launchOrFocus("1Password") end },
  { name = "Basecamp",         sub = "Web",               action = function() hs.execute("open https://3.basecamp.com") end },
  { name = "Bluetooth",        sub = "Settings",          action = function() hs.execute([[open "x-apple.systempreferences:com.apple.BluetoothSettings"]]) end },
  { name = "Brave",            sub = "Browser",           action = function() hs.application.launchOrFocus("Brave Browser") end },
  { name = "Calculator",       sub = "Math",              action = function() hs.application.launchOrFocus("Calculator") end },
  { name = "Chrome",           sub = "Browser",           action = function() hs.application.launchOrFocus("Google Chrome") end },
  { name = "Claude",           sub = "AI",                action = function() hs.application.launchOrFocus("Claude") end },
  { name = "Discord",          sub = "Comms",             action = function() hs.application.launchOrFocus("Discord") end },
  { name = "Docker",           sub = "Containers",        action = function() hs.application.launchOrFocus("Docker") end },
  { name = "Figma",            sub = "Web · figma.com",   action = function() hs.execute("open https://figma.com") end },
  { name = "Finder",           sub = "Files",             action = function() hs.application.launchOrFocus("Finder") end },
  { name = "Ghostty",          sub = "Terminal",          action = function() hs.execute("open -na Ghostty") end },
  { name = "Ghostty + nvim",   sub = "Editor",            action = function() hs.execute("open -na Ghostty --args -e nvim") end },
  { name = "GitHub",           sub = "Web · github.com",  action = function() hs.execute("open https://github.com") end },
  { name = "Google Contacts",  sub = "Web",               action = function() hs.execute("open https://contacts.google.com") end },
  { name = "Google Messages",  sub = "Brave web app",     action = function() hs.application.launchOrFocusByBundleID("com.brave.Browser.app.hpfldicfbfomlpcikngkocigghgafkph") end },
  { name = "Google Photos",    sub = "Web",               action = function() hs.execute("open https://photos.google.com") end },
  { name = "HEY (mail)",       sub = "Web",               action = function() hs.execute("open https://app.hey.com") end },
  { name = "HEY Calendar",     sub = "Web",               action = function() hs.execute("open https://app.hey.com/calendar") end },
  { name = "Lazygit",          sub = "Ghostty + lazygit", action = function() hs.execute("open -na Ghostty --args -e lazygit") end },
  { name = "LocalSend",        sub = "Cross-device file share", action = function() hs.application.launchOrFocus("LocalSend") end },
  { name = "mpv",              sub = "Media player",      action = function() hs.application.launchOrFocus("mpv") end },
  { name = "OBS Studio",       sub = "brew install --cask obs", action = function() hs.application.launchOrFocus("OBS") end },
  { name = "Obsidian",         sub = "Notes",             action = function() hs.application.launchOrFocus("Obsidian") end },
  { name = "Pinta",            sub = "Image editor",      action = function() hs.application.launchOrFocus("Pinta") end },
  { name = "Signal",           sub = "Comms",             action = function() hs.application.launchOrFocus("Signal") end },
  { name = "Slack",            sub = "Comms",             action = function() hs.application.launchOrFocus("Slack") end },
  { name = "Spotify",          sub = "Music",             action = function() hs.application.launchOrFocus("Spotify") end },
  { name = "System Settings",  sub = "macOS preferences", action = function() hs.application.launchOrFocus("System Settings") end },
  { name = "Typora",           sub = "Markdown",          action = function() hs.application.launchOrFocus("Typora") end },
  { name = "WhatsApp",         sub = "Comms",             action = function() hs.application.launchOrFocus("WhatsApp") end },
  { name = "X (Twitter)",      sub = "Brave web app",     action = function() hs.application.launchOrFocusByBundleID("com.brave.Browser.app.lodlkdfmihgonocnmddehnfgiljnadcf") end },
  { name = "YouTube",          sub = "Brave web app",     action = function() hs.application.launchOrFocusByBundleID("com.brave.Browser.app.agimnkijcaahngcdmfeangaknmldooml") end },
}

for _, m in ipairs(MICROSOFT) do table.insert(apps, { name = m.text, sub = m.sub, action = m.action }) end
table.sort(apps, function(x, y) return x.name:lower() < y.name:lower() end)

local appsChooser
showAppsMenu = function()
  if closeIfOpen(appsChooser) then return end
  local choices = {}
  for i, app in ipairs(apps) do
    table.insert(choices, { text = app.name, subText = app.sub, idx = i })
  end
  appsChooser = hs.chooser.new(function(choice)
    if choice and apps[choice.idx] then apps[choice.idx].action() end
  end)
  appsChooser:choices(choices)
  appsChooser:width(25)
  appsChooser:rows(12)
  appsChooser:bgDark(true)
  appsChooser:fgColor(COLORS.blue)
  appsChooser:subTextColor(COLORS.fg)
  appsChooser:placeholderText("Launch…")
  appsChooser:show()
end

hs.allowAppleScript(true)

hs.alert.show("Hammerspoon: keybindings ready (⌥K)")

local ghosttyConfigs = {
  os.getenv("HOME") .. "/Library/Application Support/com.mitchellh.ghostty",
  os.getenv("HOME") .. "/.config/ghostty",
}
local ghosttyReloadTimer
local function reloadGhostty()
  for _, app in ipairs(hs.application.applicationsForBundleID("com.mitchellh.ghostty")) do
    if not app:selectMenuItem({ "Ghostty", "Reload Configuration" }) then
      hs.eventtap.keyStroke({ "cmd", "shift" }, ",", 0, app)
    end
  end
end
GhosttyWatchers = {}
for _, dir in ipairs(ghosttyConfigs) do
  GhosttyWatchers[#GhosttyWatchers + 1] = hs.pathwatcher.new(dir, function(paths)
    for _, p in ipairs(paths) do
      if p:match("/config$") then
        if ghosttyReloadTimer then ghosttyReloadTimer:stop() end
        ghosttyReloadTimer = hs.timer.doAfter(0.5, reloadGhostty)
        return
      end
    end
  end):start()
end

local function consoleFrame(screen)
  local h = math.floor(screen.h * 0.5)
  local w = math.min(screen.w, h * 2)
  return { x = screen.x + math.floor((screen.w - w) / 2), y = screen.y, w = w, h = h }
end

local GHOSTTY = "com.mitchellh.ghostty"
local BOOT = hs.execute("/usr/sbin/sysctl -n kern.boottime")
local consoles = { {}, {} }
local showConsole

local function consoleApp(n)
  local saved = hs.settings.get("omarchy.console." .. n)
  if not saved or saved.boot ~= BOOT then return nil end
  local app = hs.application.applicationForPID(saved.pid)
  if app and app:bundleID() == GHOSTTY then return app end
end

local function launchConsole(n)
  local c, before = consoles[n], {}
  for _, a in ipairs(hs.application.applicationsForBundleID(GHOSTTY)) do before[a:pid()] = true end
  hs.execute("open -na Ghostty --args -e $HOME/.local/bin/omarchy-agent")
  local tries = 0
  if c.timer then c.timer:stop() end
  c.launching = true
  c.timer = hs.timer.doEvery(0.1, function()
    tries = tries + 1
    for _, a in ipairs(hs.application.applicationsForBundleID(GHOSTTY)) do
      if not before[a:pid()] and a:mainWindow() then
        c.timer:stop()
        c.launching = false
        hs.settings.set("omarchy.console." .. n, { pid = a:pid(), boot = BOOT })
        hs.timer.doAfter(0.5, function() showConsole(n, a) end)
        return
      end
    end
    if tries >= 100 then c.timer:stop(); c.launching = false end
  end)
end

local function hideConsole(n)
  local c = consoles[n]
  if not c.shown then return end
  c.shown = false
  if c.dim then c.dim:hide() end
  local app = consoleApp(n)
  if app then app:hide() end
end

local function place(n, app, win)
  local c, id = consoles[n], win:id()
  hs.execute(string.format(
    'A=aerospace; $A layout --window-id %d floating; $A move-node-to-workspace --window-id %d "$($A list-workspaces --focused)"',
    id, id))
  local screen = hs.screen.mainScreen()
  if c.dim then c.dim:delete() end
  c.dim = hs.canvas.new(screen:fullFrame())
  c.dim:appendElements({ type = "rectangle", action = "fill", fillColor = { white = 0, alpha = 0.6 } })
  c.dim:level(hs.canvas.windowLevels.normal)
  c.dim:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  c.dim:show()
  app:unhide()
  win:setFrame(consoleFrame(screen:frame()), 0)
  win:focus()
  c.pid, c.shown = app:pid(), true
end

showConsole = function(n, app)
  local win = app:mainWindow() or app:allWindows()[1]
  if win then return place(n, app, win) end
  app:unhide()
  hs.timer.doAfter(0.3, function()
    win = app:mainWindow() or app:allWindows()[1]
    if win then return place(n, app, win) end
    app:kill()
    launchConsole(n)
  end)
end

local function toggleConsole(n)
  if consoles[n].launching then return end
  if consoles[n].shown then return hideConsole(n) end
  local app = consoleApp(n)
  if app then showConsole(n, app) else launchConsole(n) end
end

hs.hotkey.bind({"cmd"}, "`", function() toggleConsole(1) end)
hs.hotkey.bind({"cmd", "shift"}, "`", function() toggleConsole(2) end)

ConsoleWatcher = hs.application.watcher.new(function(_, event, app)
  if event ~= hs.application.watcher.deactivated and event ~= hs.application.watcher.terminated then return end
  for n, c in ipairs(consoles) do
    if c.shown and app and app:pid() == c.pid then hideConsole(n) end
  end
end):start()

local BAR_HEIGHT, REMOVE_PULL = 32, 48
local barDragStart
local function screenTop(p)
  for _, s in ipairs(hs.screen.allScreens()) do
    local f = s:fullFrame()
    if p.x >= f.x and p.x < f.x + f.w and p.y >= f.y and p.y < f.y + f.h then return f.y end
  end
end
local function onSketchyBar(p)
  for _, w in ipairs(hs.window.list(true) or {}) do
    local b = w.kCGWindowBounds
    if b and (w.kCGWindowAlpha or 1) > 0 and p.x >= b.X and p.x < b.X + b.Width and p.y >= b.Y and p.y < b.Y + b.Height then
      return w.kCGWindowOwnerName == "sketchybar"
    end
  end
  return false
end
BarDragTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.leftMouseUp }, function(e)
  local p = e:location()
  if e:getType() == hs.eventtap.event.types.leftMouseDown then
    local top = screenTop(p)
    barDragStart = (top and p.y - top < BAR_HEIGHT and onSketchyBar(p)) and { x = p.x, y = p.y, top = top } or nil
  elseif barDragStart then
    local start = barDragStart
    barDragStart = nil
    if p.y - start.top >= BAR_HEIGHT + REMOVE_PULL then
      hs.task.new(os.getenv("HOME") .. "/.local/bin/omarchy-bar-remove", nil,
        { tostring(math.floor(start.x)), tostring(math.floor(start.y)) }):start()
    end
  end
  return false
end):start()

SteamWatcher = hs.application.watcher.new(function(name, event, app)
  if event == hs.application.watcher.terminated and name == "Steam" then
    hs.execute(withBrew("sketchybar --bar hidden=off"))
  end
end):start()
