#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SITE="$ROOT/docs-site"
fails=0

check() {
  if [[ "$3" == "$2" ]]; then echo "  ok    $1"
  else echo "  FAIL  $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

read -r -d '' PY <<'PYEOF'
import collections, json, pathlib, re, sys

content = pathlib.Path(sys.argv[1]) / "docs-site" / "content" / "docs"
frontmatter = re.compile(r"\A---\n(.*?)\n---\n", re.S)
field = re.compile(r"^(\w+):[ \t]*(.*)$", re.M)

def fields_of(page):
    block = frontmatter.match(page.read_text())
    return dict(field.findall(block.group(1))) if block else {}

def value_of(fields, name):
    return fields.get(name, "").strip().strip('"').strip("'")

pages = sorted([*content.glob("*.md"), *content.glob("*.mdx")])
titles, descriptions, missing = [], [], []
for page in pages:
    fields = fields_of(page)
    title, description = value_of(fields, "title"), value_of(fields, "description")
    if not title or not description:
        missing.append(page.name)
    titles.append(title)
    descriptions.append(description)

def repeated(values):
    return [value for value, count in collections.Counter(values).items() if count > 1]

meta = json.loads((content / "meta.json").read_text())
named = meta.get("pages", [])

print(f"pages={len(pages)}")
print(f"missing={','.join(missing)}")
print(f"repeated_titles={','.join(repeated(titles))}")
print(f"repeated_descriptions={','.join(repeated(descriptions))}")
print(f"unlisted={','.join(page.stem for page in pages if page.stem not in named)}")
print(f"longest_description={max((len(d) for d in descriptions), default=0)}")

SEARCHES = {
    "tiling window manager mac": "tiling-window-manager-mac",
    "aerospace config": "aerospace-config",
    "sketchybar config": "sketchybar-config",
    "hyprland on mac": "hyprland-on-mac",
    "mac rice": "mac-rice",
}
root = pathlib.Path(sys.argv[1])
site_url = "https://omarchy4mac.dividendsolo.com"
readme = (root / "README.md").read_text()
index = (content / "index.mdx").read_text()

def words(text):
    return set(re.findall(r"[a-z0-9]+", text.lower()))

without_page, without_title, unlinked_readme, unlinked_index = [], [], [], []
for query, slug in SEARCHES.items():
    page = next((content / f"{slug}{e}" for e in (".mdx", ".md") if (content / f"{slug}{e}").is_file()), None)
    if page is None:
        without_page.append(slug)
        without_title.append(slug)
        unlinked_readme.append(slug)
        unlinked_index.append(slug)
        continue
    title = value_of(fields_of(page), "title")
    if not words(query) <= words(title):
        without_title.append(f"{query} -> {title}")
    if f"({site_url}/docs/{slug})" not in readme:
        unlinked_readme.append(slug)
    if f"(/docs/{slug})" not in index:
        unlinked_index.append(slug)

print(f"searches_without_page={','.join(without_page)}")
print(f"searches_without_the_words={','.join(without_title)}")
print(f"searches_unlinked_from_readme={','.join(unlinked_readme)}")
print(f"searches_unlinked_from_index={','.join(unlinked_index)}")
print(f"volume_record={'yes' if (root / 'docs' / 'keyword-volumes.md').is_file() else 'no'}")
PYEOF

echo "the docs pages, for the crawler:"
OUT="$(python3 -c "$PY" "$ROOT")" || { echo "FAIL: the check could not read the docs pages"; exit 1; }
value() { printf '%s\n' "$OUT" | sed -n "s/^$1=//p"; }

check "there are docs pages to index" yes \
  "$([[ "$(value pages)" -ge 8 ]] && echo yes || echo no)"
check "every docs page carries a title and a description" "" "$(value missing)"
check "no two pages share a title" "" "$(value repeated_titles)"
check "no two pages share a description" "" "$(value repeated_descriptions)"
check "every docs page is named in meta.json" "" "$(value unlisted)"
check "no description is longer than 160 characters, where Google cuts it" yes \
  "$([[ "$(value longest_description)" -le 160 ]] && echo yes || echo no)"

echo "the crawler's entry points:"
check "the sitemap route exists" present \
  "$([[ -f "$SITE/app/sitemap.ts" ]] && echo present || echo missing)"
check "the sitemap answers on the site's own address" yes \
  "$(grep -q 'siteUrl' "$SITE/app/sitemap.ts" 2>/dev/null && echo yes || echo no)"
check "the sitemap lists every page the content directory holds" yes \
  "$(grep -q 'source.getPages()' "$SITE/app/sitemap.ts" 2>/dev/null && echo yes || echo no)"
check "the robots route exists" present \
  "$([[ -f "$SITE/app/robots.ts" ]] && echo present || echo missing)"
check "robots allows every crawler" yes \
  "$(grep -qE "allow: *'/'" "$SITE/app/robots.ts" 2>/dev/null && echo yes || echo no)"
check "robots names the sitemap" yes \
  "$(grep -q '/sitemap.xml' "$SITE/app/robots.ts" 2>/dev/null && echo yes || echo no)"
check "the built page check reads the sitemap and robots the build made" present \
  "$([[ -f "$SITE/scripts/check-seo.mjs" ]] && echo present || echo missing)"

echo "the five searches the card names:"
check "every search has a page of its own" "" "$(value searches_without_page)"
check "every search page carries the search's words in its title" "" "$(value searches_without_the_words)"
check "the README links every search page" "" "$(value searches_unlinked_from_readme)"
check "the docs index links every search page" "" "$(value searches_unlinked_from_index)"
check "the volume pull is recorded in docs/" yes "$(value volume_record)"

echo "the address a page answers on:"
check "the canonical origin is the docs domain" yes \
  "$(grep -q 'https://omarchy4mac.dividendsolo.com' "$SITE/lib/shared.ts" 2>/dev/null && echo yes || echo no)"
check "the layout takes its address from the shared origin" yes \
  "$(grep -q 'siteUrl' "$SITE/app/layout.tsx" 2>/dev/null && echo yes || echo no)"
check "no page answers on localhost" "" \
  "$(grep -rn 'localhost' "$SITE/app" "$SITE/lib" 2>/dev/null | sed "s|$ROOT/||" | paste -sd' ' -)"

if (( fails )); then echo "FAIL: $fails check(s)"; exit 1; fi
echo "PASS"
