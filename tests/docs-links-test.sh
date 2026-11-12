#!/bin/bash
# Every link that ships must work. This checks the links of the README, of the
# docs site's content (which is where the old README's reading now lives), of
# the changelog and of docs/:
#
#   - an http(s) link must answer 200 (redirects followed)
#   - a /docs/<slug> link must be a real page in docs-site/content/docs
#   - a /<file> link must exist under docs-site/public, or in the repo
#   - a relative path must exist, resolved from the file that prints it
#
# The two pages that come from the repo (changelog, parity-checklist) are
# committed; tests/docs-content-test.sh fails when either goes stale.
#
#   tests/docs-links-test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
fails=0

check() { # check <description> <expected> <actual>
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

read -r -d '' PY <<'PYEOF'
import concurrent.futures, pathlib, re, sys, urllib.error, urllib.request

root = pathlib.Path(sys.argv[1])
content, public = root / "docs-site/content/docs", root / "docs-site/public"
sources = [root / "README.md", root / "CHANGELOG.md", *sorted((root / "docs").glob("*.md")),
           *sorted(content.glob("*.md")), *sorted(content.glob("*.mdx"))]

LINK = re.compile(r"!?\[[^\]]*\]\(\s*([^)\s]+)")
BARE = re.compile(r"(?<![\"'(\]])(https?://[^\s)\"'<>`]+)")

def targets(text):
    for m in LINK.finditer(text):
        yield m.group(1)
    for m in BARE.finditer(text):
        yield m.group(1)

def resolves(path, src):
    """A site path or a repo-relative path -> does the thing it points at exist?"""
    path = path.split("#")[0].split("?")[0]
    if not path:
        return True
    if path.startswith("/docs"):
        slug = path[len("/docs"):].strip("/")
        if not slug:
            return any((content / f"index{e}").is_file() for e in (".md", ".mdx"))
        if any((content / f"{slug}{e}").is_file() for e in (".md", ".mdx")):
            return True
        return False
    if path.startswith("/"):
        rel = path.lstrip("/")
        return (public / rel).is_file() or (root / rel).is_file()
    return (src.parent / path).is_file() or (root / path).is_file()

def status(url):
    """The URL's status, following redirects. 200 is the only pass. A failure is
    tried again twice: a rate limit or a slow host is not a broken link."""
    import time
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"})
    code = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                code = r.status
        except urllib.error.HTTPError as e:
            code = e.code
        except Exception as e:                               # timeout, DNS, TLS
            code = str(e)
        if code == 200:
            return code
        if attempt < 2:
            time.sleep(2)
    return code

external, internal, bad = set(), [], []
for src in sources:
    for target in targets(src.read_text()):
        target = target.strip().rstrip("*.,;")   # a bare URL in bold, or at the end of a sentence
        if target.startswith(("http://", "https://")):
            external.add(target)
        elif target and not target.startswith(("mailto:", "tel:", "#")) and "${" not in target:
            internal.append((f"{src.relative_to(root)}: {target}", target, src))

for where, path, src in internal:
    if not resolves(path, src):
        bad.append(f"{where} does not resolve")

codes = {}
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    for url, code in zip(sorted(external), pool.map(status, sorted(external))):
        codes[url] = code
        if code != 200:
            bad.append(f"{url} -> {code}")

print(f"link check: {len(sources)} files, {len(external) + len(internal)} links "
      f"({len(external)} external, {len(internal)} on the site or in the repo)")
for url in sorted(codes):
    print(f"  {codes[url]} {url}")
print(f"BAD {len(bad)}")
for b in bad:
    print(f"  broken  {b}")
PYEOF

if ! OUT="$(python3 -c "$PY" "$ROOT")"; then echo "FAIL: the link check could not run"; exit 1; fi
printf '%s\n' "$OUT" | sed -n '1,/^BAD /p' | grep -v '^BAD '
BROKEN="$(printf '%s\n' "$OUT" | sed -n '/^  broken  /p' | sed 's/^  broken  //' | paste -sd'; ' -)"
BROKEN="${BROKEN//$'\n'/}"

echo "Links:"
check "every link answers 200 or resolves" "" "$BROKEN"

[[ "$fails" -eq 0 ]] && echo "PASS" || { echo "FAIL: $fails check(s)"; exit 1; }
