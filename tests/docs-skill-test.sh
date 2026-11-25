#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SITE="$ROOT/docs-site"
SKILL="$SITE/public/SKILL.md"
VERSION="$(cat "$ROOT/OMARCHY_VERSION")"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

read -r -d '' PY <<'PYEOF'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
skill = root / "docs-site" / "public" / "SKILL.md"
text = skill.read_text()
front = re.match(r"---\n(.*?)\n---\n", text, re.S)
block = front.group(1) if front else ""
fields = dict(re.findall(r"^(\w+):[ \t]*(.*)$", block, re.M))
description = fields.get("description", "")
score = re.search(r"(\d+)% of Omarchy v([\d.]+)", text)
tokens = sorted(set(re.findall(r"`([a-z][a-z0-9-]*)(?:\s|`)", text)))
named = [t for t in tokens if re.fullmatch(r"omarchy-[a-z0-9-]+|gaming-mode|quit-all|theme", t)]
missing = [t for t in named if not (root / "bin" / t).is_file()]

print(f"frontmatter={'yes' if front else 'no'}")
print(f"name={fields.get('name', '')}")
print(f"description_lines={len(description.splitlines())}")
print(f"describes_first_word={description.split()[0] if description.split() else ''}")
print(f"score={score.group(1) if score else ''}%")
print(f"version={score.group(2) if score else ''}")
print(f"commands={len(named)}")
print(f"commands_missing={' '.join(missing)}")
PYEOF

echo "the agent skill file:"
check "docs-site/public/SKILL.md is there" present \
  "$([[ -f "$SKILL" ]] && echo present || echo missing)"

if [[ -f "$SKILL" ]]; then
  OUT="$(python3 -c "$PY" "$ROOT")" || { echo "FAIL: the check could not read the skill file"; exit 1; }
  value() { printf '%s\n' "$OUT" | sed -n "s/^$1=//p"; }
  COUNT="$(value commands)"
  COUNT="${COUNT:-0}"

  check "it opens with frontmatter" yes "$(value frontmatter)"
  check "the frontmatter names the skill" omarchy4mac "$(value name)"
  check "the description is one line, so llms.txt can carry it" 1 "$(value description_lines)"
  check "the description says when to use it" Use "$(value describes_first_word)"
  check "it quotes the parity score" 75% "$(value score)"
  check "it quotes the Omarchy version" "$VERSION" "$(value version)"
  check "every command it names is in bin/" "" "$(value commands_missing)"
  if (( COUNT >= 18 )); then LISTED=yes; else LISTED=no; fi
  check "it lists the commands" yes "$LISTED"
  check "the score is the parity page's score" yes \
    "$(grep -qF '75%' "$SITE/content/docs/parity.mdx" && echo yes || echo no)"
  check "the version is the parity page's version" yes \
    "$(grep -qF "v$VERSION" "$SITE/content/docs/parity.mdx" && echo yes || echo no)"
fi

echo "how the site serves it:"
check "nginx answers a .md file as markdown" yes \
  "$(grep -qF 'location ~ \.md$' "$SITE/nginx.conf" && grep -qF 'default_type text/markdown' "$SITE/nginx.conf" && echo yes || echo no)"
check "no .dockerignore line drops the file" "" \
  "$(grep -E 'SKILL\.md|^\*\.md$|^public$' "$SITE/.dockerignore" || true)"

echo "llms.txt links it:"
check "the llms.txt route appends the skill entry" yes \
  "$(grep -qF 'skillLlmsEntry' "$SITE/app/llms.txt/route.ts" 2>/dev/null && echo yes || echo no)"
check "the entry is built from the skill file itself" yes \
  "$(grep -qF "skillPath = '/SKILL.md'" "$SITE/lib/skill.ts" 2>/dev/null && echo yes || echo no)"
check "the entry links the path" yes \
  "$(grep -qF '[Agent skill](${skillPath})' "$SITE/lib/skill.ts" 2>/dev/null && echo yes || echo no)"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
