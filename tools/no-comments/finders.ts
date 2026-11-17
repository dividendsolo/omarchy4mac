import { spawnSync } from "node:child_process";
import { basename, extname } from "node:path";
import ts from "typescript";
import { Parser } from "yaml";

export type Comment = { line: number; endLine: number; text: string; start?: number; end?: number };

export type Finder = (source: string, path: string) => Comment[];

export type Classification =
  | { kind: "checked"; find: Finder }
  | { kind: "skipped" }
  | { kind: "unknown" };

const lineAt = (source: string, offset: number) =>
  source.slice(0, offset).split("\n").length;

const span = (source: string, start: number, end: number): Comment => ({
  start,
  end,
  line: lineAt(source, start),
  endLine: lineAt(source, Math.max(start, end - 1)),
  text: source.slice(start, end).split("\n")[0].trim().slice(0, 80),
});

const shifted = (source: string, comments: Comment[], base: number): Comment[] =>
  comments.map((comment) => span(source, base + (comment.start ?? 0), base + (comment.end ?? 0)));

const byLine = (comments: Comment[]) =>
  comments.sort((a, b) => a.line - b.line || (a.start ?? 0) - (b.start ?? 0));

type Syntax = {
  line?: string[];
  block?: [string, string][];
  quotes?: string[];
  longQuotes?: [string, string][];
  nested?: boolean;
};

const scanner =
  (syntax: Syntax): Finder =>
  (source) => {
    const comments: Comment[] = [];
    const quotes = syntax.quotes ?? [];
    const closeBlock = (open: string, close: string, from: number) => {
      if (!syntax.nested) return source.indexOf(close, from);
      let depth = 1;
      for (let i = from; i < source.length; i++) {
        if (source.startsWith(open, i)) {
          depth++;
          i += open.length - 1;
        } else if (source.startsWith(close, i)) {
          depth--;
          if (depth === 0) return i;
          i += close.length - 1;
        }
      }
      return -1;
    };
    scan: for (let i = 0; i < source.length; i++) {
      for (const [open, close] of syntax.block ?? []) {
        if (source.startsWith(open, i)) {
          const end = closeBlock(open, close, i + open.length);
          const stop = end === -1 ? source.length : end + close.length;
          comments.push(span(source, i, stop));
          i = stop - 1;
          continue scan;
        }
      }
      for (const open of syntax.line ?? []) {
        if (source.startsWith(open, i)) {
          const end = source.indexOf("\n", i);
          const stop = end === -1 ? source.length : end;
          comments.push(span(source, i, stop));
          i = stop - 1;
          continue scan;
        }
      }
      for (const [open, close] of syntax.longQuotes ?? []) {
        if (source.startsWith(open, i)) {
          const end = source.indexOf(close, i + open.length);
          i = end === -1 ? source.length : end + close.length - 1;
          continue scan;
        }
      }
      const char = source[i];
      if (quotes.includes(char)) {
        for (i++; i < source.length && source[i] !== char && source[i] !== "\n"; i++) {
          if (source[i] === "\\") i++;
        }
      }
    }
    return comments;
  };

const findCssComments = scanner({ block: [["/*", "*/"]], quotes: ['"', "'"] });
const findSqlComments = scanner({ block: [["/*", "*/"]], line: ["--"], quotes: ['"', "'"] });
const findGlslComments = scanner({ block: [["/*", "*/"]], line: ["//"] });
const findSwiftComments = scanner({
  block: [["/*", "*/"]],
  line: ["//"],
  quotes: ['"'],
  longQuotes: [['"""', '"""']],
  nested: true,
});
const findLuaComments = scanner({
  block: [
    ["--[[", "]]"],
    ["--[=[", "]=]"],
    ["--[==[", "]==]"],
  ],
  line: ["--"],
  quotes: ['"', "'"],
  longQuotes: [
    ["[[", "]]"],
    ["[=[", "]=]"],
    ["[==[", "]==]"],
  ],
});

const scriptKinds: Record<string, ts.ScriptKind> = {
  ".ts": ts.ScriptKind.TS,
  ".mts": ts.ScriptKind.TS,
  ".cts": ts.ScriptKind.TS,
  ".tsx": ts.ScriptKind.TSX,
  ".js": ts.ScriptKind.JS,
  ".mjs": ts.ScriptKind.JS,
  ".cjs": ts.ScriptKind.JS,
  ".jsx": ts.ScriptKind.JSX,
};

const parseScript = (source: string, path: string) =>
  ts.createSourceFile(path, source, ts.ScriptTarget.Latest, true, scriptKinds[extname(path)] ?? ts.ScriptKind.TS);

const glslSigns =
  /^\s*#version\b|\bgl_(FragColor|FragCoord|Position|PointSize)\b|\bvoid\s+main\s*\(|\bprecision\s+(lowp|mediump|highp)\s+float\b|\b(uniform|varying|attribute)\s+(float|int|bool|vec[234]|mat[234]|sampler2D)\b/;

const isTemplate = (node: ts.Node) =>
  ts.isNoSubstitutionTemplateLiteral(node) || ts.isTemplateExpression(node);

const findShaderComments = (file: ts.SourceFile, source: string): Comment[] => {
  const comments: Comment[] = [];
  const visit = (node: ts.Node) => {
    if (isTemplate(node)) {
      const start = node.getStart(file) + 1;
      const body = source.slice(start, node.end - 1);
      if (glslSigns.test(body)) comments.push(...shifted(source, findGlslComments(body, ""), start));
      return;
    }
    node.forEachChild(visit);
  };
  visit(file);
  return comments;
};

const findScriptComments: Finder = (source, path) => {
  const file = parseScript(source, path);
  const jsxText: ts.Node[] = [];
  const collectJsxText = (node: ts.Node) => {
    if (ts.isJsxText(node)) jsxText.push(node);
    node.forEachChild(collectJsxText);
  };
  collectJsxText(file);
  const inJsxText = (pos: number) =>
    jsxText.some((text) => pos >= text.getStart(file) && pos < text.end);
  const starts = new Set<number>();
  const comments: Comment[] = [];
  const visit = (node: ts.Node) => {
    const ranges = [
      ...(ts.getLeadingCommentRanges(source, node.pos) ?? []),
      ...(ts.getTrailingCommentRanges(source, node.end) ?? []),
    ];
    for (const range of ranges) {
      if (starts.has(range.pos) || inJsxText(range.pos)) continue;
      starts.add(range.pos);
      comments.push(span(source, range.pos, range.end));
    }
    for (const child of node.getChildren(file)) visit(child);
  };
  visit(file);
  return byLine([...comments, ...findShaderComments(file, source)]);
};

export const blankCode = (source: string) =>
  source
    .replace(/^(```|~~~)[^\n]*\n[\s\S]*?^\1[^\n]*$/gm, (block) => block.replace(/[^\n]/g, " "))
    .replace(/`[^`\n]*`/g, (code) => " ".repeat(code.length));

const withSourceText = (source: string, comments: Comment[]) =>
  comments.map((comment) => ({ ...comment, text: source.split("\n")[comment.line - 1].trim().slice(0, 80) }));

const findMarkupComments: Finder = (source) => {
  const comments: Comment[] = [];
  let from = source.indexOf("<!--");
  while (from !== -1) {
    const end = source.indexOf("-->", from + 4);
    const stop = end === -1 ? source.length : end + 3;
    comments.push(span(source, from, stop));
    from = source.indexOf("<!--", stop);
  }
  return comments;
};

const findMarkdownComments: Finder = (source, path) =>
  withSourceText(source, findMarkupComments(blankCode(source), path));

const findJsxBraceComments = scanner({ block: [["{/*", "*/}"]] });

const findMdxComments: Finder = (source, path) => {
  const blank = blankCode(source);
  return withSourceText(source, byLine([...findMarkupComments(blank, path), ...findJsxBraceComments(blank, path)]));
};

const embedded = /<(script|style)\b[^>]*>([\s\S]*?)<\/\1\s*>/gi;

const findHtmlComments: Finder = (source) => {
  const comments: Comment[] = [];
  let blanked = source;
  for (const match of source.matchAll(embedded)) {
    const body = match[2];
    const start = (match.index ?? 0) + match[0].indexOf(">") + 1;
    const find = match[1].toLowerCase() === "style" ? findCssComments : findScriptComments;
    comments.push(...shifted(source, find(body, "embedded.js"), start));
    blanked = blanked.slice(0, start) + body.replace(/[^\n]/g, " ") + blanked.slice(start + body.length);
  }
  comments.push(...findMarkupComments(blanked, ""));
  return withSourceText(source, byLine(comments));
};

const findYamlComments: Finder = (source) => {
  const comments: Comment[] = [];
  const walk = (value: unknown) => {
    if (Array.isArray(value)) {
      for (const item of value) walk(item);
    } else if (value && typeof value === "object") {
      const token = value as { type?: string; offset?: number; source?: string };
      if (token.type === "comment" && typeof token.offset === "number" && token.source) {
        comments.push(span(source, token.offset, token.offset + token.source.length));
      }
      for (const child of Object.values(value)) walk(child);
    }
  };
  for (const token of new Parser().parse(source)) walk(token);
  return byLine(comments);
};

const lineCommentFinder =
  (markers: string[]): Finder =>
  (source) => {
    const comments: Comment[] = [];
    let offset = 0;
    source.split("\n").forEach((raw, index) => {
      const text = raw.trim();
      const line = index + 1;
      const marker = markers.find((m) => text.startsWith(m));
      if (marker && !(line === 1 && text.startsWith("#!"))) {
        const start = offset + raw.indexOf(marker);
        comments.push({ line, endLine: line, text: text.slice(0, 80), start, end: offset + raw.length });
      }
      offset += raw.length + 1;
    });
    return comments;
  };

const findHashLineComments = lineCommentFinder(["#"]);
const findIniComments = lineCommentFinder(["#", ";"]);

const findShellComments: Finder = (source) => {
  const comments: Comment[] = [];
  let quote: string | null = null;
  let braces = 0;
  for (let i = 0; i < source.length; i++) {
    const char = source[i];
    if (quote) {
      if (char === "\\" && quote === '"') i++;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === "\\") {
      i++;
    } else if (char === "'" || char === '"') {
      quote = char;
    } else if (char === "$" && source[i + 1] === "{") {
      braces++;
      i++;
    } else if (char === "}" && braces > 0) {
      braces--;
    } else if (char === "#" && braces === 0 && (i === 0 || /\s/.test(source[i - 1]))) {
      const end = source.indexOf("\n", i);
      const stop = end === -1 ? source.length : end;
      if (!(lineAt(source, i) === 1 && source.startsWith("#!", i))) comments.push(span(source, i, stop));
      i = stop - 1;
    }
  }
  return comments;
};

const pythonTokens = `
import io, json, sys, tokenize
out = []
try:
    for t in tokenize.generate_tokens(io.StringIO(sys.stdin.read()).readline):
        if t.type == tokenize.COMMENT:
            out.append([t.start[0], t.start[1], t.end[1]])
except (tokenize.TokenError, SyntaxError):
    print("null")
    sys.exit(0)
print(json.dumps(out))
`;

const python = (script: string, input: string) => {
  const run = spawnSync("python3", ["-c", script], { input, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (run.error || run.status === null) throw new Error(`python3 is needed to read Python files: ${run.error}`);
  return run;
};

const findPythonComments: Finder = (source, path) => {
  const tokens = JSON.parse(python(pythonTokens, source).stdout) as [number, number, number][] | null;
  if (!tokens) return findHashLineComments(source, path);
  const lines = source.split("\n");
  const starts = [0];
  for (const line of lines) starts.push(starts[starts.length - 1] + line.length + 1);
  const units = (line: string, codePoints: number) => [...line].slice(0, codePoints).join("").length;
  return tokens.map(([line, from, to]) => {
    const text = lines[line - 1];
    return span(source, starts[line - 1] + units(text, from), starts[line - 1] + units(text, to));
  });
};

const findJsonComments: Finder = (source, path) => {
  try {
    JSON.parse(source);
    return [];
  } catch {
    return findScriptComments(source, `${path}.ts`);
  }
};

const parsesAsJson = (line: string) => {
  try {
    JSON.parse(line);
    return true;
  } catch {
    return false;
  }
};

const findJsonLinesComments: Finder = (source, path) =>
  source.split("\n").every((line) => line.trim() === "" || parsesAsJson(line))
    ? []
    : findScriptComments(source, `${path}.ts`);

const findHujsonComments: Finder = (source, path) => findScriptComments(source, `${path}.ts`);

const noCommentSyntax: Finder = () => [];

const findPatchComments: Finder = (source) => {
  const comments: Comment[] = [];
  const lines = source.split("\n");
  const starts = [0];
  for (const line of lines) starts.push(starts[starts.length - 1] + line.length + 1);
  let target: string | null = null;
  let added: number[] = [];
  const flush = () => {
    if (target && added.length) {
      const text = added.map((index) => lines[index].slice(1)).join("\n");
      const textStarts = [0];
      for (const index of added) textStarts.push(textStarts[textStarts.length - 1] + lines[index].length);
      const original = (offset: number) => {
        let row = 0;
        while (row + 1 < added.length && textStarts[row + 1] <= offset) row++;
        return starts[added[row]] + 1 + offset - textStarts[row];
      };
      for (const comment of findComments(target, text)) {
        comments.push(span(source, original(comment.start ?? 0), original(comment.end ?? 0)));
      }
    }
    added = [];
  };
  lines.forEach((line, index) => {
    if (line.startsWith("+++ ")) {
      flush();
      target = line === "+++ /dev/null" ? null : line.slice(4).replace(/^b\//, "");
    } else if (line.startsWith("diff ")) {
      flush();
      target = null;
    } else if (line.startsWith("+")) {
      added.push(index);
    }
  });
  flush();
  return byLine(comments);
};

const skippedExtensions = new Set([
  ".png",
  ".jpg",
  ".jpeg",
  ".gif",
  ".webp",
  ".avif",
  ".ico",
  ".icns",
  ".pdf",
  ".zip",
  ".gz",
  ".tgz",
  ".mp3",
  ".mp4",
  ".mov",
  ".wav",
  ".m4a",
  ".woff",
  ".woff2",
  ".ttf",
  ".otf",
  ".enc",
  ".lock",
  ".lockb",
]);

const skippedNames = new Set(["package-lock.json", "bun.lock", ".keep"]);

const byExtension: Record<string, Finder> = {
  ...Object.fromEntries(Object.keys(scriptKinds).map((ext) => [ext, findScriptComments])),
  ".css": findCssComments,
  ".sql": findSqlComments,
  ".yml": findYamlComments,
  ".yaml": findYamlComments,
  ".json": findJsonComments,
  ".geojson": findJsonComments,
  ".webmanifest": findJsonComments,
  ".jsonl": findJsonLinesComments,
  ".hujson": findHujsonComments,
  ".html": findHtmlComments,
  ".htm": findHtmlComments,
  ".md": findMarkdownComments,
  ".mdc": findMarkdownComments,
  ".mdx": findMdxComments,
  ".svg": findMarkupComments,
  ".xml": findMarkupComments,
  ".plist": findMarkupComments,
  ".sh": findShellComments,
  ".zsh": findShellComments,
  ".py": findPythonComments,
  ".swift": findSwiftComments,
  ".lua": findLuaComments,
  ".toml": findHashLineComments,
  ".txt": findHashLineComments,
  ".theme": findHashLineComments,
  ".ini": findIniComments,
  ".service": findIniComments,
  ".slice": findIniComments,
  ".timer": findIniComments,
  ".socket": findIniComments,
  ".tsv": noCommentSyntax,
  ".csv": noCommentSyntax,
  ".patch": findPatchComments,
  ".diff": findPatchComments,
  ".sample": findShellComments,
  ".example": findShellComments,
};

const byName: Record<string, Finder> = {
  Dockerfile: findHashLineComments,
  ".gitignore": findHashLineComments,
  ".dockerignore": findHashLineComments,
  ".gitattributes": findHashLineComments,
};

const backupExtensions = new Set([".orig"]);

const directives: { lastLine?: number; pattern: RegExp }[] = [
  { lastLine: 1, pattern: /^#!/ },
  { pattern: /^\/\/\/\s*<reference\b/ },
  { lastLine: 2, pattern: /^#.*?coding[:=]\s*[-\w.]+/ },
];

export function isDirective(comment: Comment): boolean {
  return directives.some(
    ({ lastLine, pattern }) => (lastLine === undefined || comment.line <= lastLine) && pattern.test(comment.text),
  );
}

const withoutDirectives =
  (find: Finder): Finder =>
  (source, path) =>
    find(source, path).filter((comment) => !isDirective(comment));

export function classify(path: string, source: string): Classification {
  const name = basename(path);
  if (backupExtensions.has(extname(name))) return classify(path.slice(0, -extname(name).length), source);
  if (skippedNames.has(name) || skippedExtensions.has(extname(name)) || source === "" || source.includes("\0")) {
    return { kind: "skipped" };
  }
  const named = byName[name] ?? byExtension[extname(name)];
  if (named) return { kind: "checked", find: withoutDirectives(named) };
  if (extname(name) && !name.startsWith(".")) return { kind: "unknown" };
  return { kind: "checked", find: withoutDirectives(findShellComments) };
}

export function findComments(path: string, source: string): Comment[] {
  const classification = classify(path, source);
  return classification.kind === "checked" ? classification.find(source, path) : [];
}

const parseError = (path: string, source: string): string | null => {
  const ext = extname(path.replace(/\.orig$/, ""));
  if (ext in scriptKinds) {
    const file = parseScript(source, path) as ts.SourceFile & { parseDiagnostics?: ts.Diagnostic[] };
    const first = file.parseDiagnostics?.[0];
    return first ? ts.flattenDiagnosticMessageText(first.messageText, "\n") : null;
  }
  if (ext === ".py") {
    const run = python("import ast, sys\nast.parse(sys.stdin.read())", source);
    return run.status === 0 ? null : (run.stderr.trim().split("\n").pop() ?? "syntax error");
  }
  if (ext === ".json" || ext === ".webmanifest" || ext === ".geojson") {
    return parsesAsJson(source) ? null : "invalid JSON";
  }
  if (ext === ".yml" || ext === ".yaml") {
    return [...new Parser().parse(source)].some((token) => token.type === "error") ? "invalid YAML" : null;
  }
  return null;
};

export function assertParses(path: string, before: string, after: string): void {
  if (parseError(path, before) !== null) return;
  const error = parseError(path, after);
  if (error !== null) throw new Error(`${path}: the stripped file no longer parses (${error}); fix it by hand`);
}
