#!/bin/bash
# Checks bin/omarchy-screensaver: tty echo is off from startup, not only while
# `read -s` waits, so a key that ends it never flashes in the corner
# (Omarchy 4.5, omacom/omarchy#16596). Runs the script in a pty (python3) and
# reads the tty's ECHO flag while the script waits for the window size, before
# any `read`.
#
#   tests/screensaver-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin/omarchy-screensaver"
fails=0
check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}
command -v python3 >/dev/null || { echo "FAIL: python3 is not installed"; exit 1; }

T="$(mktemp -d)"; mkdir -p "$T/home/.local/bin"
# A stand-in ttfx (the CI runner has none): without it the script's loop spins
# on "command not found" and floods the pty.
printf '#!/bin/sh\nexec sleep 30\n' > "$T/home/.local/bin/ttfx"; chmod +x "$T/home/.local/bin/ttfx"

# A 24x80 pty keeps the script in its size wait for 2 s: no read runs then.
# The parent drains the pty (macOS blocks a writer on a small, full pty buffer)
# and kills the whole session with SIGKILL if SIGTERM does not end it in 2 s,
# so the test can never hang the run.
ECHO_STATE="$(HOME="$T/home" python3 - "$BIN" <<'PY'
import fcntl, os, pty, select, signal, struct, sys, termios, time
master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
pid = os.fork()
if pid == 0:
    os.setsid()
    fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
    for fd in (0, 1, 2): os.dup2(slave, fd)
    os.execv("/bin/bash", ["bash", sys.argv[1]])
def drain(seconds):
    end = time.time() + seconds
    while time.time() < end:
        if select.select([master], [], [], 0.05)[0]:
            try: os.read(master, 4096)
            except OSError: return
drain(0.8)
print("off" if not termios.tcgetattr(slave)[3] & termios.ECHO else "on", flush=True)
os.kill(pid, signal.SIGTERM)
end = time.time() + 2
while time.time() < end and os.waitpid(pid, os.WNOHANG) == (0, 0):
    drain(0.05)
try:
    os.killpg(pid, signal.SIGKILL)
    os.waitpid(pid, 0)
except (ProcessLookupError, ChildProcessError):
    pass
PY
)"
rm -rf "$T"

echo "screensaver tty:"
check "echo is off from startup, so the exit key does not flash" off "$ECHO_STATE"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
