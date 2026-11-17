import re
import subprocess
import sys
from pathlib import Path

TOML_TOKENS = re.compile(
    r"'''.*?'''|\"\"\".*?\"\"\"|'[^'\n]*'|\"(?:\\.|[^\"\\\n])*\"|(?P<comment>#[^\n]*)",
    re.S,
)
LUA_TOKENS = re.compile(
    r"(?P<long_comment>--\[(?P<eq>=*)\[.*?\](?P=eq)\])"
    r"|\[(?P<eq2>=*)\[.*?\](?P=eq2)\]"
    r"|\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*'"
    r"|(?P<comment>--[^\n]*)",
    re.S,
)
LUA_HEREDOC = re.compile(r"<<-?\s*['\"]?(LUA\w*)['\"]?")


def comments(tokens, text, first_line=1):
    for match in tokens.finditer(text):
        group = match.group("comment") or match.groupdict().get("long_comment")
        if group:
            yield first_line + text.count("\n", 0, match.start()), group.strip()[:80]


def lua_bodies(text):
    lines = text.split("\n")
    index = 0
    while index < len(lines):
        opener = LUA_HEREDOC.search(lines[index])
        index += 1
        if not opener:
            continue
        start = index
        while index < len(lines) and lines[index].strip() != opener.group(1):
            index += 1
        yield start + 1, "\n".join(lines[start:index])


def gaps(root):
    tracked = subprocess.run(
        ["git", "-C", str(root), "ls-files", "*.toml", "*.sh", "bin/*"],
        capture_output=True, text=True, check=True,
    ).stdout.split()
    for path in tracked:
        file = Path(root, path)
        if file.is_symlink() or not file.is_file():
            continue
        text = file.read_text(errors="replace")
        if path.endswith(".toml"):
            for line, comment in comments(TOML_TOKENS, text):
                yield path, line, comment
        else:
            for first_line, body in lua_bodies(text):
                for line, comment in comments(LUA_TOKENS, body, first_line):
                    yield path, line, comment


if __name__ == "__main__":
    found = list(gaps(sys.argv[1] if len(sys.argv) > 1 else "."))
    for path, line, comment in found:
        print(f"  {path}:{line}  {comment}", file=sys.stderr)
    print(f"comment-gaps: {len(found)} comments the checker does not see")
    sys.exit(1 if found else 0)
