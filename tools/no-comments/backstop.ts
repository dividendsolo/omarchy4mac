#!/usr/bin/env bun
import { readFileSync } from "node:fs";
import { basename, extname, join } from "node:path";
import { trackedFiles } from "./check";
import { blankCode, classify, isDirective } from "./finders";

export type Miss = { path: string; line: number; text: string };

const slash = /^\s*(\/\/|\/\*)/;
const markup = /^\s*<!--/;
const hash = /^\s*#/;
const semicolon = /^\s*;/;
const dashes = /^\s*--/;
const jsxComment = /^\s*\{\/\*/;

const hashTypes = new Set([
  ".py",
  ".sh",
  ".zsh",
  ".yml",
  ".yaml",
  ".toml",
  ".txt",
  ".theme",
  ".sample",
  ".example",
]);
const iniTypes = new Set([".ini", ".service", ".slice", ".timer", ".socket"]);
const markdownTypes = new Set([".md", ".mdc", ".mdx"]);
const markupTypes = new Set([".html", ".htm", ".svg", ".xml", ".plist"]);
const dashTypes = new Set([".sql", ".lua"]);
const noMarkers = new Set([".patch", ".diff", ".tsv", ".csv"]);

export function markers(path: string): RegExp[] {
  const name = basename(path).replace(/\.orig$/, "");
  const ext = extname(name);
  if (noMarkers.has(ext)) return [];
  if (markdownTypes.has(ext)) return ext === ".mdx" ? [markup, jsxComment] : [markup];
  if (iniTypes.has(ext)) return [hash, semicolon];
  if (hashTypes.has(ext) || !ext || name.startsWith(".") || name === "Dockerfile") return [hash];
  if (dashTypes.has(ext)) return [dashes, slash];
  if (markupTypes.has(ext)) return [markup, slash];
  return [slash];
}

export function missedLines(path: string, source: string): Miss[] {
  const classification = classify(path, source);
  if (classification.kind !== "checked") return [];
  const reported = new Set<number>();
  for (const comment of classification.find(source, path)) {
    for (let n = comment.line; n <= comment.endLine; n++) reported.add(n);
  }
  const patterns = markers(path);
  const ext = extname(basename(path).replace(/\.orig$/, ""));
  const searched = markdownTypes.has(ext) ? blankCode(source) : source;
  const original = source.split("\n");
  return searched.split("\n").flatMap((text, index) => {
    const line = index + 1;
    if (reported.has(line) || !patterns.some((pattern) => pattern.test(text))) return [];
    const trimmed = original[index].trim();
    if (isDirective({ line, endLine: line, text: trimmed })) return [];
    return [{ path, line, text: trimmed.slice(0, 80) }];
  });
}

export function backstop(root: string, paths: string[]): Miss[] {
  return trackedFiles(root, paths).flatMap((path) => missedLines(path, readFileSync(join(root, path), "utf8")));
}

if (import.meta.main) {
  const misses = backstop(process.argv[2] ?? ".", process.argv.slice(3).length ? process.argv.slice(3) : ["."]);
  for (const miss of misses) console.error(`  ${miss.path}:${miss.line}  ${miss.text}`);
  console.log(`backstop: ${misses.length} comment-like lines the checker did not report`);
  process.exit(misses.length ? 1 : 0);
}
