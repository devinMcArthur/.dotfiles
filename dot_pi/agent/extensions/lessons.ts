/**
 * lessons.ts — Append "lessons learned" to AGENTS.md files, either global
 * (~/.pi/agent/AGENTS.md) or project-scoped (<git-root>/AGENTS.md).
 *
 * Two entry points:
 *   • `/lesson [global|project] <text>` — manual command.
 *   • `save_lesson` tool — pi calls this on its own when it detects a
 *     correction or expressed preference (see AGENTS.md for guidance).
 *
 * Chezmoi integration: if the target AGENTS.md is chezmoi-managed, the
 * lesson is appended to the chezmoi SOURCE file, then propagated to the
 * live TARGET via `chezmoi apply`, then committed to the source repo with
 * a descriptive message. This eliminates drift and makes lessons portable
 * to other machines via the dotfiles repo. If the target isn't
 * chezmoi-managed, falls back to writing the live file directly.
 *
 * Lessons save silently (no confirm). Auto-discovered from
 * ~/.pi/agent/extensions/lessons.ts.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { homedir } from "node:os";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve, relative } from "node:path";
import { execFileSync } from "node:child_process";

const GLOBAL_AGENTS = join(homedir(), ".pi/agent/AGENTS.md");
const SECTION_HEADER = "## Lessons learned";
const SECTION_HEADER_RE = /^## Lessons learned\s*$/m;

/** Walk up from `start` looking for a `.git` directory; return that dir. */
function findGitRoot(start: string): string | null {
  let dir = resolve(start);
  while (true) {
    if (existsSync(join(dir, ".git"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function todayISO(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/**
 * Insert a lesson bullet into existing AGENTS.md content under the
 * "## Lessons learned" section (creating it if missing), newest first.
 */
function injectLesson(content: string, bullet: string): string {
  let out = content;
  if (out && !out.endsWith("\n")) out += "\n";

  const m0 = SECTION_HEADER_RE.exec(out);
  const idx = m0 ? m0.index : -1;

  if (idx === -1) {
    if (out === "") {
      return (
        `# Project notes for pi\n\n` +
        `Auto-loaded by pi when cwd is inside this directory.\n\n` +
        `${SECTION_HEADER}\n\n<!-- Auto-appended by save_lesson. Newest first. -->\n${bullet}\n`
      );
    }
    return (
      out +
      `\n${SECTION_HEADER}\n\n<!-- Auto-appended by save_lesson. Newest first. -->\n${bullet}\n`
    );
  }

  // Insert immediately after the section header line (and the optional
  // existing HTML comment), so the newest lesson is first.
  const after = idx + SECTION_HEADER.length;
  let cursor = out.indexOf("\n", after);
  if (cursor === -1) cursor = out.length;
  const tail = out.slice(cursor);
  const m = tail.match(/^\n(?:\n<!--[^\n]*-->)?/);
  const insertAt = cursor + (m ? m[0].length : 0);
  return out.slice(0, insertAt) + `\n${bullet}` + out.slice(insertAt);
}

/** Return chezmoi's source-path for `target`, or null if not managed. */
function chezmoiSourcePath(target: string): string | null {
  try {
    const out = execFileSync("chezmoi", ["source-path", target], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    return out || null;
  } catch {
    return null;
  }
}

/** First N chars of the lesson, single-line, for commit subject. */
function commitSubject(text: string, max = 60): string {
  const oneLine = text.replace(/\s+/g, " ").trim();
  return oneLine.length <= max ? oneLine : oneLine.slice(0, max - 1) + "…";
}

function appendLessonViaChezmoi(
  target: string,
  sourcePath: string,
  text: string,
): void {
  const bullet = `- ${todayISO()}: ${text.trim()}`;

  // 1) Append to chezmoi SOURCE.
  const sourceContent = existsSync(sourcePath)
    ? readFileSync(sourcePath, "utf8")
    : "";
  writeFileSync(sourcePath, injectLesson(sourceContent, bullet), "utf8");

  // 2) Propagate to live TARGET. --force so we don't get prompted about the
  //    target already differing from the previous source (which it does,
  //    because we just edited source).
  execFileSync("chezmoi", ["apply", "--force", target], {
    stdio: ["ignore", "ignore", "ignore"],
  });

  // 3) Commit just this file in the chezmoi source repo. Don't sweep in
  //    other in-flight changes. Best-effort — silently skip if anything
  //    fails (e.g. no git config, repo missing).
  try {
    const sourceRoot = execFileSync("chezmoi", ["source-path"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const rel = relative(sourceRoot, sourcePath);
    execFileSync("git", ["-C", sourceRoot, "add", rel], {
      stdio: ["ignore", "ignore", "ignore"],
    });
    execFileSync(
      "git",
      [
        "-C",
        sourceRoot,
        "commit",
        "-m",
        `lessons: ${commitSubject(text)}`,
        "--",
        rel,
      ],
      { stdio: ["ignore", "ignore", "ignore"] },
    );
  } catch {
    // Auto-commit is a convenience, not a correctness requirement.
  }
}

function appendLessonDirect(target: string, text: string): void {
  mkdirSync(dirname(target), { recursive: true });
  const bullet = `- ${todayISO()}: ${text.trim()}`;
  const content = existsSync(target) ? readFileSync(target, "utf8") : "";
  writeFileSync(target, injectLesson(content, bullet), "utf8");
}

/** Public: persist a lesson to `target`. Prefers chezmoi-source flow when
 *  the target is chezmoi-managed. */
function appendLesson(target: string, text: string): {
  via: "chezmoi" | "direct";
} {
  const sourcePath = chezmoiSourcePath(target);
  if (sourcePath) {
    appendLessonViaChezmoi(target, sourcePath, text);
    return { via: "chezmoi" };
  }
  appendLessonDirect(target, text);
  return { via: "direct" };
}

type Scope = "global" | "project";

function resolveTargetFile(scope: Scope, cwd: string): {
  file: string;
  effectiveScope: Scope;
  note?: string;
} {
  if (scope === "project") {
    const root = findGitRoot(cwd);
    if (!root) {
      return {
        file: GLOBAL_AGENTS,
        effectiveScope: "global",
        note: "no git repo found; saved to global instead",
      };
    }
    return { file: join(root, "AGENTS.md"), effectiveScope: "project" };
  }
  return { file: GLOBAL_AGENTS, effectiveScope: "global" };
}

function parseManualArgs(args: string): { scope: Scope; text: string } | null {
  const trimmed = args.trim();
  if (!trimmed) return null;
  const m = trimmed.match(/^(global|project)\s+(.+)$/s);
  if (m) return { scope: m[1] as Scope, text: m[2] };
  return { scope: "global", text: trimmed };
}

export default function (pi: ExtensionAPI) {
  // ---- Manual: /lesson [global|project] <text> ----------------------------
  pi.registerCommand("lesson", {
    description: "Save a lesson learned to AGENTS.md (global or project).",
    getArgumentCompletions: (prefix: string) => {
      const opts = ["global", "project"];
      const items = opts
        .filter((s) => s.startsWith(prefix))
        .map((value) => ({ value, label: value }));
      return items.length ? items : null;
    },
    handler: async (args, ctx) => {
      const parsed = parseManualArgs(args ?? "");
      if (!parsed) {
        ctx.ui.notify("Usage: /lesson [global|project] <text>", "warning");
        return;
      }
      const { file, effectiveScope, note } = resolveTargetFile(
        parsed.scope,
        ctx.cwd,
      );
      const { via } = appendLesson(file, parsed.text);
      const where =
        effectiveScope === "global" ? "global AGENTS.md" : `${file}`;
      ctx.ui.notify(
        `Saved lesson (${effectiveScope}, via ${via}) → ${where}` +
          (note ? ` (${note})` : ""),
        "info",
      );
    },
  });

  // ---- Tool: save_lesson (called by pi itself) ----------------------------
  pi.registerTool({
    name: "save_lesson",
    label: "Save lesson",
    description:
      "Persist a durable lesson learned to AGENTS.md so future pi sessions " +
      "know it. Use when the user corrects you, expresses a stable " +
      "preference, or states a fact about themselves or their setup. " +
      "Saves silently; user has already opted into this in AGENTS.md.",
    promptSnippet:
      "save_lesson: persist a correction or stable preference to AGENTS.md (global or project scope)",
    promptGuidelines: [
      "Call save_lesson when the user corrects a pattern, expresses a " +
        "durable preference, or states a fact about themselves or their " +
        "tools. Prefer specific, short, one-line lessons. Do not call " +
        "save_lesson for one-off task preferences — only for things you " +
        "would want to remember in a future, unrelated session.",
    ],
    parameters: Type.Object({
      scope: Type.Union(
        [Type.Literal("global"), Type.Literal("project")],
        {
          description:
            "global = ~/.pi/agent/AGENTS.md; project = <git-root>/AGENTS.md if cwd is inside a repo.",
        },
      ),
      text: Type.String({
        description:
          "One-line lesson. Be specific. The current date is prepended automatically.",
      }),
    }),
    async execute(_id, params, _signal, _onUpdate, ctx) {
      const { file, effectiveScope, note } = resolveTargetFile(
        params.scope,
        ctx.cwd,
      );
      const { via } = appendLesson(file, params.text);
      const msg =
        `Saved (${effectiveScope}, via ${via}) to ${file}` +
        (note ? ` — ${note}` : "");
      return {
        content: [{ type: "text", text: msg }],
        details: { file, effectiveScope, via, note },
      };
    },
  });
}
