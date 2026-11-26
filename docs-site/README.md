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

Write `content/docs/<name>.md` or `.mdx` with frontmatter (`title`, and a
`description` — one sentence written for the search result), then add `<name>`
to `content/docs/meta.json`. Quote a description that contains a colon: YAML
reads the rest as a nested mapping and the build stops. `tests/docs-seo-test.sh`
in the repo root fails on a page with no title or description, on two pages that
share one, and on a description longer than 160 characters.

A page reaches Google through `app/sitemap.ts`, which lists every page the
content directory holds, and `app/robots.ts`, which allows crawling and names
the sitemap. `npm run check-seo` reads the two files the build wrote and fails
when the sitemap does not carry every page in `meta.json`, when a listed
address has no built page, or when robots stops allowing crawlers. CI runs it
after `npm run build` in the docs job.

MDX parses `<` and `{` as JSX, so put anything like `<file>` or `<cmd>` in
backticks, as the keybinding tables do.

## Deploy

Kamal, from `config/deploy.yml`, to ezio: the image builds this directory and
nginx serves the static export from it, with `/up` for the healthcheck.

```sh
cd docs-site && kamal deploy
```

Vercel project `omarchy4mac-docs` is connected to this repo, and its
deployments answer 402 (`DEPLOYMENT_DISABLED`) under a fair-use CPU limit until
2026-12-24; the site may move back there. Nothing here needs an env var;
`NEXT_PUBLIC_SITE_URL` overrides the address the pages answer on — the Open
Graph address, the sitemap and robots.txt — and the default is
`https://omarchy4mac.dividendsolo.com`.
