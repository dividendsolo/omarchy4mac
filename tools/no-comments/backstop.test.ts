import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, expect, it } from "vitest";
import { backstop, missedLines } from "./backstop";
import { checkAll, checkDiff, trackedFiles } from "./check";

const here = dirname(fileURLToPath(import.meta.url));
const root = execFileSync("git", ["-C", here, "rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();

const repos: string[] = [];
const repo = (files: Record<string, string>) => {
  const dir = mkdtempSync(join(tmpdir(), "no-comments-"));
  repos.push(dir);
  const git = (...args: string[]) => execFileSync("git", ["-C", dir, ...args], { encoding: "utf8" });
  git("init", "-q", "-b", "main");
  for (const [path, text] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, path)), { recursive: true });
    writeFileSync(join(dir, path), text);
  }
  git("add", ".");
  git("-c", "user.name=t", "-c", "user.email=t", "commit", "-q", "-m", "init");
  return dir;
};

afterEach(() => {
  for (const dir of repos.splice(0)) rmSync(dir, { recursive: true, force: true });
});

describe("backstop", () => {
  it("flags a comment-like line the checker did not report", () => {
    const source = 'SCRIPT = """#!/bin/sh\n# embedded shell\necho hi\n"""\n';
    expect(missedLines("a.py", source).map((miss) => miss.line)).toEqual([2]);
  });

  it("passes lines the checker reports and the allowed directives", () => {
    expect(missedLines("a.ts", "#!/usr/bin/env bun\n// why\n/// <reference types=\"x\" />\n")).toEqual([]);
    expect(missedLines("a.md", "# Title\n<!-- x -->\n```js\n// code\n```\n")).toEqual([]);
  });

  it("would have caught the first checker's gaps", () => {
    const html = "<script>\n// why\n</script>\n";
    expect(missedLines("a.html", html)).toEqual([]);
    const shader = "const f = `#version 300 es\n// why\nvoid main() {}\n`;\n";
    expect(missedLines("a.js", shader)).toEqual([]);
  });

  it("finds no missed comment in the files this repo checks", () => {
    const scope = existsSync(join(root, "bin", "no-comments")) ? "." : relative(root, here);
    expect(backstop(root, [scope])).toEqual([]);
  });
});

describe("tracked symlinks", () => {
  it("never follows a tracked symlink out of the repo, in the check or the strip", () => {
    const outside = mkdtempSync(join(tmpdir(), "no-comments-outside-"));
    repos.push(outside);
    writeFileSync(join(outside, "secret.sh"), "# outside the repo\n");
    const dir = repo({ "a.ts": "const a = 1;\n" });
    symlinkSync(join(outside, "secret.sh"), join(dir, "link.sh"));
    execFileSync("git", ["-C", dir, "add", "link.sh"]);
    expect(checkAll(dir, ["."])).toEqual([]);
    expect(trackedFiles(dir, ["."])).toEqual(["a.ts"]);
  });
});

describe("the per-repo ignore list", () => {
  it("leaves the paths in .no-comments-ignore out of the check", () => {
    const dir = repo({
      ".no-comments-ignore": ".agents/skills\nvendor/x.ts\n",
      ".agents/skills/a/run.sh": "# vendored\n",
      "vendor/x.ts": "// vendored\n",
      "src/a.ts": "// ours\n",
    });
    expect(checkAll(dir, ["."]).map((o) => o.path)).toEqual(["src/a.ts"]);
    expect(backstop(dir, ["."])).toEqual([]);
  });

  it("leaves ignored paths out of the diff check", () => {
    const dir = repo({ ".no-comments-ignore": ".agents/skills\n", "a.ts": "const a = 1;\n" });
    writeFileSync(join(dir, "a.ts"), "// ours\n");
    mkdirSync(join(dir, ".agents/skills"), { recursive: true });
    writeFileSync(join(dir, ".agents/skills/b.ts"), "// vendored\n");
    execFileSync("git", ["-C", dir, "add", "."]);
    execFileSync("git", ["-C", dir, "-c", "user.name=t", "-c", "user.email=t", "commit", "-q", "-m", "b"]);
    expect(checkDiff(dir, "HEAD~1").map((o) => o.path)).toEqual(["a.ts"]);
  });
});
