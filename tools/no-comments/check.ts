#!/usr/bin/env bun
import { execFileSync } from "node:child_process";
import { existsSync, lstatSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { classify, type Comment } from "./finders";

export type Offence = { path: string; line: number; text: string };

const git = (root: string, args: string[]) =>
  execFileSync("git", ["-C", root, ...args], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });

export function addedLines(diff: string): Map<string, Set<number>> {
  const added = new Map<string, Set<number>>();
  let current: Set<number> | null = null;
  for (const line of diff.split("\n")) {
    if (line.startsWith("+++ ")) {
      const path = line.slice(4);
      current = path === "/dev/null" ? null : new Set();
      if (current) added.set(path.replace(/^b\//, ""), current);
      continue;
    }
    const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/.exec(line);
    if (hunk && current) {
      const start = Number(hunk[1]);
      const count = hunk[2] === undefined ? 1 : Number(hunk[2]);
      for (let n = start; n < start + count; n++) current.add(n);
    }
  }
  return added;
}

export const IGNORE_FILE = ".no-comments-ignore";

export function ignoredPaths(root: string): string[] {
  const file = join(root, IGNORE_FILE);
  if (!existsSync(file)) return [];
  return readFileSync(file, "utf8")
    .split("\n")
    .map((line) => line.trim().replace(/^\.\//, "").replace(/\/+$/, ""))
    .filter(Boolean);
}

export const isIgnored = (path: string, ignored: string[]) =>
  ignored.some((entry) => path === entry || path.startsWith(`${entry}/`));

const isRegularFile = (root: string, path: string) =>
  existsSync(join(root, path)) && lstatSync(join(root, path)).isFile();

export function trackedFiles(root: string, paths: string[]): string[] {
  const ignored = ignoredPaths(root);
  return git(root, ["ls-files", "--", ...paths])
    .split("\n")
    .filter((path) => path && !isIgnored(path, ignored) && isRegularFile(root, path));
}

const touches = (comment: Comment, lines: Set<number>) => {
  for (let n = comment.line; n <= comment.endLine; n++) if (lines.has(n)) return true;
  return false;
};

function scan(root: string, path: string, lines?: Set<number>): Offence[] {
  const source = readFileSync(join(root, path), "utf8");
  const classification = classify(path, source);
  if (classification.kind === "skipped") return [];
  if (classification.kind === "unknown") {
    return [{ path, line: 1, text: "unknown file type: teach tools/no-comments/finders.ts to read it (the source is in agent-stack)" }];
  }
  return classification
    .find(source, path)
    .filter((comment) => !lines || touches(comment, lines))
    .map((comment) => ({ path, line: comment.line, text: comment.text }));
}

export function checkDiff(root: string, base: string): Offence[] {
  const diff = git(root, ["diff", "--unified=0", "--no-color", "--diff-filter=AMR", "--merge-base", base]);
  const ignored = ignoredPaths(root);
  return [...addedLines(diff)].flatMap(([path, lines]) =>
    isRegularFile(root, path) && !isIgnored(path, ignored) ? scan(root, path, lines) : [],
  );
}

export function checkAll(root: string, paths: string[]): Offence[] {
  return trackedFiles(root, paths).flatMap((path) => scan(root, path));
}

if (import.meta.main) {
  const { values } = parseArgs({
    options: {
      root: { type: "string", default: "." },
      diff: { type: "string" },
      all: { type: "string", multiple: true },
    },
  });
  const root = values.root;
  const allPaths = (values.all ?? []).filter((path) => existsSync(join(root, path)));
  const offences = [
    ...(values.diff ? checkDiff(root, values.diff) : []),
    ...(allPaths.length ? checkAll(root, allPaths) : []),
  ];
  const unique = [...new Map(offences.map((o) => [`${o.path}:${o.line}`, o])).values()];
  if (unique.length) {
    console.error(`No comments allowed (AGENTS.md "No comments"). Found ${unique.length}:`);
    for (const o of unique) console.error(`  ${o.path}:${o.line}  ${o.text}`);
    process.exit(1);
  }
  console.log("no-comments: clean.");
}
