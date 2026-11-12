# omarchy4mac docs site

The readable version of this repo's documentation: [Fumadocs](https://fumadocs.dev)
(Next.js 16, React 19, Tailwind 4). The README is the signpost; the reading is
here.

## Run it

```sh
npm install
npm run dev      # http://localhost:3000
npm run build    # the production build Vercel runs
```

Use a port other than 3000 if something else holds it: `npm run dev -- -p 4321`.

## Where the content lives

`content/docs/` — one file per page, named in `content/docs/meta.json`, which
sets the sidebar order. The pages moved here from the repo's old README:
what omarchy4mac is, install, uninstall, what you get, keybindings, themes,
troubleshooting, and the parity scorecard.

Two pages are built from files in the repo, so the repo keeps one copy of each:
`content/docs/changelog.md` comes from the repo's `CHANGELOG.md`, and
`content/docs/parity-checklist.md` from `docs/parity-v4.md`. Both pages are
committed — the site builds on its own, because Vercel uploads only this
directory and the repo's files are not in that upload. Edit the repo file, then
run `npm run sync-content`, which rewrites both pages.
`tests/docs-content-test.sh` in the repo root runs `npm run check-content` and
fails when a page no longer matches its source.

`tests/readme-test.sh` in the repo root reads `content/docs/keybindings.md`:
the keybinding and alias tables there must match `aerospace/aerospace.toml`,
`hammerspoon/init.lua` and `zsh/omarchy.zsh`. `tests/docs-links-test.sh` checks
every link in the README, this content and the repo's `docs/`.

## Adding a page

Write `content/docs/<name>.md` or `.mdx` with frontmatter (`title`, and
`description` when it helps), then add `<name>` to `content/docs/meta.json`.
Quote a description that contains a colon: YAML reads the rest as a nested
mapping and the build stops.

MDX parses `<` and `{` as JSX, so put anything like `<file>` or `<cmd>` in
backticks, as the keybinding tables do.

## Deploy

Vercel, on the `Dividend Solo's projects` team, project `omarchy4mac-docs`,
with this directory as the project root:

```sh
cd docs-site && npx vercel deploy --prod
```

The project is linked in `.vercel/` (gitignored). Nothing here needs an env
var; `NEXT_PUBLIC_SITE_URL` overrides the Open Graph address on a custom
domain.
