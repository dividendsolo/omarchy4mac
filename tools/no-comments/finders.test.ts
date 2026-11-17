import { describe, expect, it } from "vitest";
import { addedLines } from "./check";
import { assertParses, classify, findComments } from "./finders";
import { stripComments } from "./strip";

const lines = (path: string, source: string) =>
  findComments(path, source).map((comment) => comment.line);

describe("findComments", () => {
  it("flags line and block comments in TypeScript", () => {
    expect(
      lines("a.ts", "const a = 1; // why\n/* block */\nconst b = 2;\n"),
    ).toEqual([1, 2]);
  });

  it("flags lint and type suppressions", () => {
    expect(
      lines(
        "a.ts",
        "// biome-ignore lint: x\n// @ts-expect-error\nconst a: string = 1;\n",
      ),
    ).toEqual([1, 2]);
  });

  it("flags a JSX comment", () => {
    expect(
      lines(
        "a.tsx",
        "export const A = () => (\n  <div>\n    {/* note */}\n  </div>\n);\n",
      ),
    ).toEqual([3]);
  });

  it("passes a shebang line", () => {
    expect(lines("a.ts", "#!/usr/bin/env bun\nconsole.log(1);\n")).toEqual([]);
    expect(lines("run.sh", "#!/bin/sh\necho hi\n")).toEqual([]);
  });

  it("ignores comment markers inside strings, URLs, templates, regexes and JSX text", () => {
    const source = [
      'const url = "https://example.com/#top";',
      "const t = `a // b /* c */`;",
      "const r = /\\/\\//g;",
      'const s = "/* not */";',
      'export const A = () => <a href="https://x.dev">// text</a>;',
    ].join("\n");
    expect(lines("a.tsx", source)).toEqual([]);
  });

  it("flags CSS comments but not markers inside strings or urls", () => {
    const source =
      'a { b: url("https://x.dev/*y"); content: "/* no */"; }\n/* yes */\nc { d: url(https://x.dev); }\n';
    expect(lines("a.css", source)).toEqual([2]);
  });

  it("flags YAML comments but not a hash inside a value", () => {
    const source = '# top\nkey: "a # b"\nother: a#b\nlist:\n  - x # trailing\nmore:\n  # inner\n  - y\n';
    expect(lines("a.yml", source)).toEqual([1, 5, 7]);
  });

  it("flags comments in JSONC configs and passes plain JSON", () => {
    expect(
      lines("tsconfig.json", '{\n  // why\n  "a": "https://x.dev/#y"\n}\n'),
    ).toEqual([2]);
    expect(lines("package.json", '{ "a": "// b" }')).toEqual([]);
  });

  it("flags hash comments in Dockerfiles and ignore files", () => {
    expect(lines("Dockerfile", "# syntax\nFROM oven/bun\n")).toEqual([1]);
    expect(lines(".gitignore", "# deps\n/node_modules\n")).toEqual([1]);
  });


  it("flags markup comments in HTML, Markdown and SVG", () => {
    expect(lines("a.md", "# Title\n<!-- hidden -->\n")).toEqual([2]);
    expect(lines("a.md", "Say `<!-- -->` here.\n```html\n<!-- example -->\n```\n")).toEqual([]);
    expect(lines("a.svg", "<svg><!-- x --></svg>")).toEqual([1]);
  });

  it("flags SQL comments", () => {
    expect(lines("a.sql", "select '--' as a; -- why\n/* b */\n")).toEqual([1, 2]);
  });

  it("reads other extensionless files as hash-comment files", () => {
    expect(lines("bin/tool", "#!/bin/sh\n# why\necho 1\n")).toEqual([2]);
  });

  it("fails closed on a file type it cannot read", () => {
    expect(classify("notes.rst", "text").kind).toBe("unknown");
    expect(classify("logo.png", "binary").kind).toBe("skipped");
  });
});

describe("gaps in the first checker", () => {
  it("flags // and /* */ inside <script> and <style> in .html and .htm", () => {
    const source = [
      "<html>",
      "<style>",
      "/* palette */",
      "a { color: red; }",
      "</style>",
      "<script type=\"module\">",
      "// wire the button",
      "const u = \"https://x.dev/#y\";",
      "/* block */",
      "</script>",
      "<p>a // b</p>",
      "</html>",
    ].join("\n");
    expect(lines("a.html", source)).toEqual([3, 7, 9]);
    expect(lines("a.htm", source)).toEqual([3, 7, 9]);
  });

  it("flags comments in GLSL inside a JS or TS template string", () => {
    const shader = [
      "const frag = `#version 300 es",
      "precision highp float;",
      "// the flow",
      "void main() { float w = 1.0; /* falloff */ }",
      "`;",
    ].join("\n");
    expect(lines("a.js", shader)).toEqual([3, 4]);
    expect(lines("a.ts", shader)).toEqual([3, 4]);
    const noVersion = "const v = `\nuniform vec2 u_pos;\n// why\nvoid main() { gl_Position = vec4(0.0); }\n`;\n";
    expect(lines("a.js", noVersion)).toEqual([3]);
  });

  it("passes // inside a template string that holds no GLSL", () => {
    expect(lines("a.js", "const u = `\n// not a comment\nhttps://x.dev\n`;\n")).toEqual([]);
  });
});

describe("file types", () => {
  it("reads Python with the tokenizer: a hash inside a string is not a comment", () => {
    const source = '#!/usr/bin/env python3\n# why\nx = "a # b"\ny = 1  # trailing\nz = """\n# in a docstring\n"""\n';
    expect(lines("a.py", source)).toEqual([2, 4]);
  });

  it("reads MDX and MDC as Markdown, with JSX comments in MDX", () => {
    expect(lines("a.mdx", "# Title\n{/* hidden */}\n<!-- x -->\n```js\n// code\n```\n")).toEqual([2, 3]);
    expect(lines("a.mdc", "---\ndescription: x\n---\n# Rule\n<!-- x -->\n")).toEqual([5]);
  });

  it("reads systemd units and INI files", () => {
    expect(lines("a.service", "# why\n[Unit]\n; old\nDescription=a # b\n")).toEqual([1, 3]);
    expect(lines("lab.slice", "# why\n[Slice]\nCPUQuota=100%\n")).toEqual([1]);
    expect(lines("pytest.ini", "[pytest]\n# why\naddopts = -q\n")).toEqual([2]);
  });

  it("reads property lists as markup", () => {
    expect(lines("a.plist", "<?xml version=\"1.0\"?>\n<!-- why -->\n<plist></plist>\n")).toEqual([2]);
  });

  it("reads Swift", () => {
    const source = 'let a = "// no" // why\n/* block\n */\nlet b = """\n// no\n"""\n';
    expect(lines("a.swift", source)).toEqual([1, 2]);
  });

  it("reads Lua line and block comments but not strings", () => {
    const source = "-- why\nlocal a = \"-- no\"\n--[[ block\n]]\nlocal b = [[ -- no ]]\nlocal c = 1 -- trailing\n";
    expect(lines("init.lua", source)).toEqual([1, 3, 6]);
  });

  it("reads HuJSON, web manifests and JSON Lines", () => {
    expect(lines("policy.hujson", '{\n  // why\n  "a": "https://x.dev/#y",\n}\n')).toEqual([2]);
    expect(lines("manifest.webmanifest", '{ "name": "a // b" }\n')).toEqual([]);
    expect(lines("a.jsonl", '{"a": "// b"}\n{"c": 1}\n')).toEqual([]);
    expect(lines("a.jsonl", '{"a": 1}\n// why\n{"c": 1}\n')).toEqual([2]);
  });

  it("reads zsh as shell and btop themes as hash files", () => {
    expect(lines("a.zsh", "#!/bin/zsh\n# why\necho \"a # b\"\n")).toEqual([2]);
    expect(lines("btop.theme", "# why\ntheme[main_bg]=\"#111c18\"\n")).toEqual([1]);
  });

  it("reads TSV as data with no comment syntax", () => {
    expect(classify("a.tsv", "a\tb\n").kind).toBe("checked");
    expect(lines("a.tsv", "# a\tb\n")).toEqual([]);
  });

  it("reads the added lines of a patch as the file the patch changes", () => {
    const source = [
      "diff --git a/x.ts b/x.ts",
      "--- a/x.ts",
      "+++ b/x.ts",
      "@@ -1,2 +1,3 @@",
      " const a = 1;",
      "+// why",
      "-const b = 2;",
      "+const b = 3;",
      "",
    ].join("\n");
    expect(lines("fix.patch", source)).toEqual([6]);
  });

  it("reads a .orig backup as the file it backs up", () => {
    expect(lines("CONTEXT.md.orig", "# Title\n<!-- x -->\n")).toEqual([2]);
    expect(lines("a.ts.orig", "// why\n")).toEqual([1]);
  });

  it("skips binary files", () => {
    expect(classify("data.bin", "ab\0cd").kind).toBe("skipped");
    expect(classify("a.pdf", "%PDF-1.4").kind).toBe("skipped");
  });
});

describe("allowed directives", () => {
  it("passes a shebang, a triple-slash reference and a Python coding line", () => {
    expect(lines("a.ts", '/// <reference types="vite/client" />\nconst a = 1;\n')).toEqual([]);
    expect(lines("a.py", "#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\nx = 1\n")).toEqual([]);
    expect(lines("a.py", "# vim: set fileencoding=utf-8 :\nx = 1\n")).toEqual([]);
    expect(lines("a.py", "x = 1\n\n# coding: utf-8\n")).toEqual([3]);
  });
});

describe("addedLines", () => {
  it("reads the added line numbers of each file from a zero-context diff", () => {
    const diff = [
      "diff --git a/x.ts b/x.ts",
      "--- a/x.ts",
      "+++ b/x.ts",
      "@@ -3,0 +4,2 @@",
      "+a",
      "+b",
      "@@ -10 +12 @@",
      "-c",
      "+d",
      "diff --git a/y.ts b/y.ts",
      "--- a/y.ts",
      "+++ /dev/null",
      "@@ -1 +0,0 @@",
    ].join("\n");
    expect([...addedLines(diff)].map(([path, set]) => [path, [...set]])).toEqual([
      ["x.ts", [4, 5, 12]],
    ]);
  });
});

describe("stripComments", () => {
  it("keeps the directives a toolchain needs", () => {
    expect(stripComments("a.ts", '/// <reference types="x" />\n// why\nconst a = 1;\n')).toBe(
      '/// <reference types="x" />\nconst a = 1;\n',
    );
    expect(stripComments("a.py", "#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\n# why\nx = 1\n")).toBe(
      "#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\nx = 1\n",
    );
  });

  it("strips comments inside <script> and <style> and in shader strings", () => {
    expect(stripComments("a.html", "<script>\n// why\nrun();\n</script>\n<style>/* x */a{}</style>\n")).toBe(
      "<script>\nrun();\n</script>\n<style>a{}</style>\n",
    );
    expect(stripComments("a.js", "const f = `#version 300 es\n// why\nvoid main() {}\n`;\n")).toBe(
      "const f = `#version 300 es\nvoid main() {}\n`;\n",
    );
  });

  it("strips Python comments but not hashes in strings", () => {
    expect(stripComments("a.py", 'x = "a # b"  # why\n# gone\ny = 2\n')).toBe('x = "a # b"\ny = 2\n');
  });

  it("keeps two words apart when an inline comment sat between them", () => {
    expect(stripComments("a.ts", "let/* why */b = 2;\nf(/* x */);\n")).toBe("let b = 2;\nf();\n");
  });

  it("refuses a result that no longer parses", () => {
    expect(() => assertParses("a.py", "x = 1\n", "x = (\n")).toThrow(/no longer parses/);
    expect(() => assertParses("a.ts", "f();\n", "f(;\n")).toThrow(/no longer parses/);
    expect(() => assertParses("a.json", "{}", "{")).toThrow(/no longer parses/);
    expect(() => assertParses("a.py", "x = (\n", "x = (\n")).not.toThrow();
  });

  it("drops whole-line comments, trims trailing ones and keeps the shebang", () => {
    const source = '#!/bin/sh\n# header\n\nx=1 # why\n\n# about y\necho "a # b"\n';
    expect(stripComments("run.sh", source)).toBe('#!/bin/sh\n\nx=1\n\necho "a # b"\n');
  });

  it("does not leave a double blank line where a comment block sat between blanks", () => {
    expect(stripComments("a.ts", "a();\n\n// one\n// two\n\nb();\n")).toBe("a();\n\nb();\n");
  });

  it("removes a multi-line block comment", () => {
    expect(stripComments("a.css", "a {}\n/* one\n   two */\nb {}\n")).toBe("a {}\nb {}\n");
  });

  it("strips YAML and shell trailing comments but not values", () => {
    expect(stripComments("a.yml", 'a: 1 # one\nb: "x # y"\n')).toBe('a: 1\nb: "x # y"\n');
    expect(stripComments("run.sh", '#!/bin/sh\necho "a # b" # c\necho ${x#y}\n')).toBe(
      '#!/bin/sh\necho "a # b"\necho ${x#y}\n',
    );
  });
});
