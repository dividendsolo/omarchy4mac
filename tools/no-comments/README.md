# no-comments

The checker and stripper for the global rule "No comments in code" (dotfiles AGENTS.md). Every repo carries
a copy in `tools/no-comments/` and runs it through `bin/no-comments`, in its lint script and in
`.github/workflows/ci.yml`.

The source is `tools/no-comments/` in agent-stack. A repo never edits its copy: a fix lands in agent-stack,
then the install command copies it out again. agent-stack's tests fail when a repo listed in `repos.txt`
holds a copy on main that differs from the source.

## Commands

From an agent-stack checkout:

- `uv run --with pyyaml python3 tools/no-comments/install.py install <repo dir>`: copy the checker in, write `bin/no-comments`,
  add it to every `lint` script (or add a `lint` script to the root `package.json`), and add a step to the
  first job of `.github/workflows/ci.yml` (or write a ci.yml). Run it again after every source change.
- `uv run --with pyyaml python3 tools/no-comments/install.py check <repo dir>...`: exit 1 when a copy differs from the source.
- `uv run --with pyyaml python3 tools/no-comments/install.py check-remote`: the same for every repo in `repos.txt`, read from
  its main branch on GitHub.

In a repo that holds a copy:

- `bin/no-comments`: check every tracked file.
- `bun tools/no-comments/check.ts --diff origin/main`: check only the lines a branch adds.
- `bun tools/no-comments/strip.ts . [paths]`: remove the comments. It refuses a file that would no longer
  parse and names it for a hand fix.
- `bun tools/no-comments/backstop.ts . [paths]`: a plain text search for lines that start with a comment
  marker; it lists every one the checker did not report.

## What it reads

Every text file type in our repos, each with its own comment syntax: TypeScript and JavaScript (the
TypeScript parser, plus GLSL in template strings), Python (the Python tokenizer, so `#` inside a string is
not a comment), HTML (markup comments, and `//` and `/* */` inside `<script>` and `<style>`), Markdown,
MDX, MDC, CSS, SQL, YAML, JSON, HuJSON, JSON Lines, shell, Swift, Lua, INI and systemd units, TOML,
property lists, SVG, XML, patches (the added lines, read as the patched file) and `.orig` backups (read as
the file they back up). TSV and CSV have no comment syntax. A file type it does not know fails the check.
Binary files are skipped.

## Allowed directives

These are the only comments the checker passes, because a toolchain needs them:

- a shebang on line 1 (`#!/usr/bin/env bun`);
- a TypeScript triple-slash reference (`/// <reference types="..." />`);
- a Python encoding line on line 1 or 2 (`# -*- coding: utf-8 -*-`).

## Vendored files

`.no-comments-ignore` at the repo root lists paths the checker, the stripper and the backstop leave out, one
per line: a file, or a directory and everything under it. Use it only for third-party files, for example
installed skills under `.agents/skills`.

## The backstop

`backstop.test.ts` runs the backstop over the whole repo when the repo has `bin/no-comments`, and over the
checker's own directory in agent-stack. A line it lists is a gap in the checker: teach the checker in
agent-stack, never the copy.

## The skip guard

`vitest.config.ts` runs `vitest.no-skip.ts`, a reporter that fails `bun run test` on any skipped or todo
test, in agent-stack and in every copy.
