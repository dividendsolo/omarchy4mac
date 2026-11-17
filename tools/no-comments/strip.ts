#!/usr/bin/env bun
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { trackedFiles } from "./check";
import { assertParses, classify } from "./finders";

export function stripComments(path: string, source: string): string {
  const classification = classify(path, source);
  if (classification.kind !== "checked") return source;
  const comments = classification.find(source, path);
  if (!comments.length) return source;
  const masked = new Uint8Array(source.length);
  for (const comment of comments) {
    if (comment.start === undefined || comment.end === undefined) {
      throw new Error(`${path}:${comment.line}: no offsets for ${comment.text}`);
    }
    masked.fill(1, comment.start, comment.end);
  }
  const output: string[] = [];
  let droppedSinceKept = false;
  let offset = 0;
  for (const line of source.split("\n")) {
    const lineMask = masked.subarray(offset, offset + line.length);
    offset += line.length + 1;
    if (!lineMask.includes(1)) {
      const blankAfterDrop = line.trim() === "" && droppedSinceKept;
      const previousBlank = output.length === 0 || output[output.length - 1].trim() === "";
      droppedSinceKept = false;
      if (blankAfterDrop && previousBlank) continue;
      output.push(line);
      continue;
    }
    let kept = "";
    for (let i = 0; i < line.length; i++) {
      if (!lineMask[i]) {
        kept += line[i];
        continue;
      }
      const next = line[i + 1];
      if (!lineMask[i + 1] && /[\w$]$/.test(kept) && next !== undefined && /[\w$]/.test(next)) kept += " ";
    }
    if (kept.trim() === "") {
      droppedSinceKept = true;
      continue;
    }
    output.push(kept.replace(/[ \t]+$/, ""));
  }
  while (output.length > 1 && output[0].trim() === "") output.shift();
  const stripped = output.join("\n");
  assertParses(path, source, stripped);
  return stripped;
}

if (import.meta.main) {
  const root = process.argv[2] ?? ".";
  const paths = process.argv.slice(3);
  const files = trackedFiles(root, paths.length ? paths : ["."]);
  let changed = 0;
  let removed = 0;
  let failed = 0;
  for (const path of files) {
    const full = join(root, path);
    const source = readFileSync(full, "utf8");
    let stripped: string;
    try {
      stripped = stripComments(path, source);
    } catch (error) {
      console.error(String(error));
      failed++;
      continue;
    }
    if (stripped === source) continue;
    changed++;
    if (stripped.trim() === "") {
      rmSync(full);
      removed++;
      continue;
    }
    writeFileSync(full, stripped);
  }
  console.log(`strip: ${changed} files changed, ${removed} emptied files removed, ${failed} left for a hand fix`);
  if (failed) process.exit(1);
}
