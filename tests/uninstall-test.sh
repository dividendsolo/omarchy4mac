#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

stub() {
  printf '#!/bin/bash\n%s\n' "$2" > "$TMP/stubs/$1"
  chmod +x "$TMP/stubs/$1"
}

setup() {
  rm -rf "$TMP/home" "$TMP/stubs" "$TMP/brew" "$TMP/log" "$TMP/running"
  mkdir -p "$TMP/home" "$TMP/stubs" "$TMP/brew/bin"
  : > "$TMP/log"; : > "$TMP/running"
  for name in osascript defaults launchctl killall; do
    stub "$name" "echo \"$name \$*\" >> \"$TMP/log\""
  done
  stub pgrep "grep -qx -- \"\${@: -1}\" \"$TMP/running\""
  stub pkill "echo \"pkill \$*\" >> \"$TMP/log\""
  printf '#!/bin/bash\necho "brew $*" >> "%s"\n' "$TMP/log" > "$TMP/brew/bin/brew"
  chmod +x "$TMP/brew/bin/brew"
}

run_uninstall() {
  HOME="$TMP/home" OMARCHY4MAC_DIR="$TMP/clone" HOMEBREW_PREFIX="$TMP/brew" \
    PATH="$TMP/stubs:/usr/bin:/bin:/usr/sbin:/sbin" /bin/bash "$ROOT/uninstall.sh" "$@" >/dev/null 2>&1
}

logged() { grep -qxF -- "$1" "$TMP/log" && echo yes || echo no; }

echo "uninstall.sh stops SketchyBar and borders when brew is not on PATH (omarchy4mac#106):"
setup
run_uninstall
check "the uninstall exits 0" "yes" "$( [ $? = 0 ] && echo yes || echo no )"
check "brew services stop sketchybar runs" "yes" "$(logged "brew services stop sketchybar")"
check "brew services stop borders runs" "yes" "$(logged "brew services stop borders")"

echo "a SketchyBar or borders still running after the stop is ended:"
setup
printf 'sketchybar\nborders\n' > "$TMP/running"
run_uninstall
check "pkill -x sketchybar runs" "yes" "$(logged "pkill -x sketchybar")"
check "pkill -x borders runs" "yes" "$(logged "pkill -x borders")"

echo "nothing left running, nothing killed:"
setup
run_uninstall
check "no pkill for sketchybar" "no" "$(logged "pkill -x sketchybar")"

echo "--dry-run stops nothing:"
setup
printf 'sketchybar\n' > "$TMP/running"
run_uninstall --dry-run
check "no brew services stop" "no" "$(logged "brew services stop sketchybar")"
check "no pkill" "no" "$(logged "pkill -x sketchybar")"

echo "--remove-packages finds brew without PATH too:"
setup
run_uninstall --remove-packages
check "brew uninstall sketchybar runs" "yes" "$(logged "brew uninstall sketchybar")"

exit $fails
