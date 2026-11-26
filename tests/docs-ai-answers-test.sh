#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CONTENT="$ROOT/docs-site/content/docs"
FILE="$ROOT/docs/ai-answers.md"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

echo "docs/ai-answers.md:"
check "the file is there" present "$([[ -f "$FILE" ]] && echo present || echo missing)"

if [[ -f "$FILE" ]]; then
  read -r -d '' PY <<'PYEOF'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
content = root / "docs-site" / "content" / "docs"
text = (root / "docs" / "ai-answers.md").read_text()

questions = [
    "can I run omarchy on a mac",
    "omarchy for macos",
    "best tiling window manager for mac",
    "how to make macos look like hyprland",
    "aerospace vs yabai",
]
missing = [q for q in questions if f"| {q} |" not in text]

rows = [line for line in text.splitlines() if line.startswith("|") and line.endswith("|")]
header = rows[0] if rows else ""
has_reask = "| Re-ask |" in header

pages = sorted(set(re.findall(r"`(/docs(?:/[a-z0-9-]+)?)`", text)))
unresolved = []
no_description = []
for path in pages:
    slug = path[len("/docs"):].strip("/")
    candidates = [content / f"{slug}{ext}" for ext in (".md", ".mdx")] if slug else [
        content / f"index{ext}" for ext in (".md", ".mdx")
    ]
    page = next((p for p in candidates if p.is_file()), None)
    if page is None:
        unresolved.append(path)
        continue
    front = re.match(r"---\n(.*?)\n---\n", page.read_text(), re.S)
    description = re.search(r"^description:\s*(.+)$", front.group(1) if front else "", re.M)
    if not description or not description.group(1).strip().strip('"'):
        no_description.append(path)

print(f"questions_missing={' '.join(missing)}")
print(f"reask_column={'yes' if has_reask else 'no'}")
print(f"pages={' '.join(pages)}")
print(f"pages_unresolved={' '.join(unresolved)}")
print(f"pages_without_description={' '.join(no_description)}")
PYEOF

  if ! OUT="$(python3 -c "$PY" "$ROOT")"; then echo "FAIL: the check could not read the file"; exit 1; fi
  value() { printf '%s\n' "$OUT" | sed -n "s/^$1=//p"; }

  check "the card's five questions are in the table, word for word" "" "$(value questions_missing)"
  check "the table has a Re-ask column" yes "$(value reask_column)"
  check "every /docs page the file names is a content page" "" "$(value pages_unresolved)"
  check "every page it names carries the description llms.txt prints" "" "$(value pages_without_description)"
fi

echo "the answer-first line on each page:"
check "the home page opens on what the product is" yes \
  "$(grep -qF 'omarchy4mac is Omarchy 4 for macOS: a native port that brings the Omarchy' \
    "$CONTENT/index.mdx" && echo yes || echo no)"
INSTALL_LEAD="$(sed -n 's/^description: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$CONTENT/install.mdx")"
INSTALL_FIRST="$(awk 'f==2 && NF {print; exit} /^---$/ {f++}' "$CONTENT/install.mdx")"
check "the install answer names omarchy4mac as the thing that runs on a Mac" yes \
  "$([[ "$INSTALL_LEAD" == "Yes: omarchy4mac puts Omarchy 4's desktop on a Mac, with no Linux and no dual boot"* ]] && echo yes || echo no)"
check "the install page body opens on what install.sh does, not on the lead again" yes \
  "$([[ "$INSTALL_FIRST" == '`install.sh` '* ]] && echo yes || echo no)"
check "docs/ai-answers.md links the card that holds the re-ask" yes \
  "$(grep -qE 'github\.com/dividendsolo/omarchy4mac/issues/[0-9]+' "$FILE" && echo yes || echo no)"
check "the what-you-get page opens on AeroSpace, not on a heading" yes \
  "$(grep -qF 'The window manager is **AeroSpace**' "$CONTENT/what-you-get.mdx" && echo yes || echo no)"

echo "how the answers reach llms.txt:"
check "llms.txt is built from the docs index" yes \
  "$(grep -qF 'docsLlms.index()' "$ROOT/docs-site/app/llms.txt/route.ts" 2>/dev/null && echo yes || echo no)"
check "the index is built from each page's description" yes \
  "$(grep -qF 'docsLlms = llms(source' "$ROOT/docs-site/lib/source.ts" 2>/dev/null && echo yes || echo no)"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
