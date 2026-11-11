#!/bin/bash
# Checks the Omarchy 4.5 Brave and web app fixes (#40): the browser key falls
# back to Safari when the https handler names a browser that is gone
# (omacom/omarchy#16422), ⌥⇧L copies the front tab's URL in any Brave profile
# or web app window (#10292, #10308), and omarchy-chromium-setup gives every
# installed Chromium browser the 1Password and Bitwarden native messaging hosts
# and overlay scrollbars (#14456). Runs in a throwaway HOME with open,
# osascript, pbcopy and defaults stubbed, so nothing on the Mac is touched.
#
#   tests/browser-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HERE/../bin"
LUA="${HAMMERSPOON_LUA:-$HERE/../hammerspoon/init.lua}"
fails=0
check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

LUAJIT="$(command -v luajit)"   # found before PATH shrinks to the stubs
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" LOG="$TMP/log" STUBS="$TMP/stubs"
mkdir -p "$HOME" "$STUBS"
export PATH="$STUBS:/usr/bin:/bin"
# open and defaults log their command line. osascript answers the installed-app
# check (NSWorkspace) from $INSTALLED and a browser's URL from $URL.
for tool in open defaults; do
  printf '#!/bin/bash\necho "%s $*" >>"$LOG"\n' "$tool" >"$STUBS/$tool"
done
cat >"$STUBS/osascript" <<'EOF'
#!/bin/bash
if [[ "$*" == *URLForApplicationWithBundleIdentifier* ]]; then
  [[ " $INSTALLED " == *" ${@: -1} "* ]] && echo "/Applications/${@: -1}.app"
  exit 0
fi
echo "osascript $*" >>"$LOG"
[[ -n ${URL:-} ]] && echo "$URL"
EOF
printf '#!/bin/bash\ncat >"%s/clipboard"\n' "$TMP" >"$STUBS/pbcopy"
chmod +x "$STUBS"/*

handler() { # handler <bundle id>: make it the https handler in LaunchServices
  local plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  mkdir -p "${plist%/*}"
  plutil -create xml1 "$plist"
  plutil -insert LSHandlers -json "[{\"LSHandlerURLScheme\":\"https\",\"LSHandlerRoleAll\":\"$1\"}]" "$plist"
}

echo "omarchy-launch-browser:"
handler com.brave.Browser
: >"$LOG"; INSTALLED="com.brave.Browser" "$BIN_DIR/omarchy-launch-browser"
check "an installed default browser opens" "open -b com.brave.Browser" "$(cat "$LOG")"
: >"$LOG"; INSTALLED="" "$BIN_DIR/omarchy-launch-browser"
check "a default browser that is gone falls back to Safari" "open -b com.apple.Safari" "$(cat "$LOG")"
: >"$LOG"; INSTALLED="" "$BIN_DIR/omarchy-launch-browser" --app=https://app.hey.com
check "a web app with the default browser gone opens in Safari" "open -b com.apple.Safari https://app.hey.com" "$(cat "$LOG")"
: >"$LOG"; INSTALLED="com.brave.Browser" "$BIN_DIR/omarchy-launch-browser" --private
check "a private window still opens in the installed browser" "open -nb com.brave.Browser --args --incognito" "$(cat "$LOG")"

echo "omarchy-copy-url:"
rm -f "$TMP/clipboard"; : >"$LOG"
out=$(URL="https://example.com/a?b=1" "$BIN_DIR/omarchy-copy-url" com.brave.Browser)
check "Brave: the front window's tab goes to the clipboard" "https://example.com/a?b=1" "$(cat "$TMP/clipboard")"
check "Brave: asks Brave for the front window's active tab (any profile)" \
  'osascript -e tell application id "com.brave.Browser" to URL of active tab of front window' "$(cat "$LOG")"
check "Brave: shows the copied URL" "Copy URL|||https://example.com/a?b=1" "$out"
: >"$LOG"
URL="https://music.youtube.com/" "$BIN_DIR/omarchy-copy-url" com.brave.Browser.app.cinhimbnkkaeohfgghhklpknlkffjgod >/dev/null
check "an installed web app asks its browser" \
  'osascript -e tell application id "com.brave.Browser" to URL of active tab of front window' "$(cat "$LOG")"
: >"$LOG"
URL="https://apple.com/" "$BIN_DIR/omarchy-copy-url" com.apple.Safari >/dev/null
check "Safari: asks for the front document" 'osascript -e tell application id "com.apple.Safari" to URL of front document' "$(cat "$LOG")"
rm -f "$TMP/clipboard"; : >"$LOG"
out=$("$BIN_DIR/omarchy-copy-url" com.mitchellh.ghostty); status=$?
check "not a browser: exits 1" 1 "$status"
check "not a browser: asks nothing and copies nothing" "|" "$(cat "$LOG")|$(cat "$TMP/clipboard" 2>/dev/null)"
out=$(URL="" "$BIN_DIR/omarchy-copy-url" com.brave.Browser); status=$?
check "no window: exits 1 and copies nothing" "1|" "$status|$(cat "$TMP/clipboard" 2>/dev/null)"

echo "hammerspoon ⌥⇧L:"
bound=$([[ -n $LUAJIT ]] || { echo "luajit is not installed (brew install luajit)"; exit 0; }; HOME="$TMP" "$LUAJIT" - "$LUA" <<'LUAEOF'
local function stub()
  return setmetatable({}, { __index = function() return stub() end, __call = function() return stub() end })
end
hs = stub()
require = function() return stub() end
local hotkeys, ran = {}, {}
hs.execute = function() return "" end
hs.hotkey = { bind = function(mods, key, fn) hotkeys[table.concat(mods, "+") .. "+" .. key] = fn end }
hs.task = { new = function(_, _, args) ran[#ran + 1] = args[#args]; return stub() end }
hs.application = setmetatable({ frontmostApplication = function()
  return { bundleID = function() return "com.brave.Browser" end }
end }, { __index = function() return stub() end })
dofile(arg[1])
local fn = hotkeys["alt+shift+l"]
if fn then fn() end
print(ran[#ran] or "unbound")
LUAEOF
)
check "⌥⇧L runs omarchy-copy-url for the front app" "~/.local/bin/omarchy-copy-url 'com.brave.Browser'" "$bound"

echo "omarchy-chromium-setup:"
AS="$HOME/Library/Application Support"
# Brave and Helium are installed (each has its profile folder); Chrome is not.
# 1Password registered its host with Brave only, Bitwarden with Helium only.
mkdir -p "$AS/BraveSoftware/Brave-Browser/NativeMessagingHosts" "$AS/net.imput.helium/NativeMessagingHosts"
echo '{"name":"com.1password.1password"}' >"$AS/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.1password.1password.json"
echo '{"name":"com.8bit.bitwarden"}' >"$AS/net.imput.helium/NativeMessagingHosts/com.8bit.bitwarden.json"
: >"$LOG"; "$BIN_DIR/omarchy-chromium-setup" >/dev/null; status=$?
check "exits 0" 0 "$status"
check "1Password's host reaches Helium" '{"name":"com.1password.1password"}' \
  "$(cat "$AS/net.imput.helium/NativeMessagingHosts/com.1password.1password.json" 2>/dev/null)"
check "Bitwarden's host reaches Brave" '{"name":"com.8bit.bitwarden"}' \
  "$(cat "$AS/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.8bit.bitwarden.json" 2>/dev/null)"
check "a browser that is not installed gets nothing" no "$([[ -e "$AS/Google/Chrome" ]] && echo yes || echo no)"
check "overlay scrollbars for each installed browser, and only those" \
  "defaults write com.brave.Browser AppleShowScrollBars -string WhenScrolling
defaults write net.imput.helium AppleShowScrollBars -string WhenScrolling" "$(cat "$LOG")"
echo '{"name":"com.8bit.bitwarden","path":"vendor"}' >"$AS/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.8bit.bitwarden.json"
"$BIN_DIR/omarchy-chromium-setup" >/dev/null
check "a second run keeps the host a vendor wrote" '{"name":"com.8bit.bitwarden","path":"vendor"}' \
  "$(cat "$AS/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.8bit.bitwarden.json")"

echo
if [ "$fails" -eq 0 ]; then echo "all browser checks pass"; else echo "$fails browser check(s) failed"; exit 1; fi
