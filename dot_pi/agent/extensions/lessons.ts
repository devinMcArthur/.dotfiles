/**
 * lessons.ts — Append "lessons learned" to AGENTS.md files, either global
 * (~/.pi/agent/AGENTS.md) or project-scoped (<git-root>/AGENTS.md).
 *
 * Two entry points:
 *   • `/lesson [global|project] <text>` — manual command.
 *   • `save_lesson` tool — pi calls this on its own when it detects a
 *     correction or expressed preference (see AGENTS.md for guidance).
 *
 * Lessons are saved **silently** (no confirm prompt). They are appended
 * under a `## Lessons learned` section (created if missing), newest first.
 *
 * Auto-discovered by pi from ~/.pi/agent/extensions/lessons.ts.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { homedir } from "node:os";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

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
 * Append a lesson to the target file under "## Lessons learned".
 * Creates the file (with a minimal header) and the section as needed.
 * New entries go directly under the section header (newest first).
 */
function appendLesson(file: string, text: string): void {
  mkdirSync(dirname(file), { recursive: true });
  const bullet = `- ${todayISO()}: ${text.trim()}`;
  let content = existsSync(file) ? readFileSync(file, "utf8") : "";

  if (content && !content.endsWith("\n")) content += "\n";

  // Match the header as a full line — not as a substring inside prose.
  const m0 = SECTION_HEADER_RE.exec(content);
  const idx = m0 ? m0.index : -1;
  if (idx === -1) {
    if (content === "") {
      content =
        `# Project notes for pi\n\n` +
        `Auto-loaded by pi when cwd is inside this directory.\n\n` +
        `${SECTION_HEADER}\n\n<!-- Auto-appended by save_lesson. Newest first. -->\n${bullet}\n`;
    } else {
      content += `\n${SECTION_HEADER}\n\n<!-- Auto-appended by save_lesson. Newest first. -->\n${bullet}\n`;
    }
  } else {
    // Insert immediately after the section header line (and the optional
    // existing HTML comment), so the newest lesson is first.
    const after = idx + SECTION_HEADER.length;
    // Find end of next line (header) plus an optional comment line.
    let cursor = content.indexOf("\n", after);
    if (cursor === -1) cursor = content.length;
    // Skip one blank line + an optional HTML comment line.
    const tail = content.slice(cursor);
    const m = tail.match(/^\n(?:\n<!--[^\n]*-->)?/);
    const insertAt = cursor + (m ? m[0].length : 0);
    content =
      content.slice(0, insertAt) + `\n${bullet}` + content.slice(insertAt);
  }

  writeFileSync(file, content, "utf8");
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
      appendLesson(file, parsed.text);
      const where =
        effectiveScope === "global" ? "global AGENTS.md" : `${file}`;
      ctx.ui.notify(
        `Saved lesson (${effectiveScope}) → ${where}${note ? ` (${note})` : ""}`,
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
      appendLesson(file, params.text);
      const msg =
        `Saved (${effectiveScope}) to ${file}` +
        (note ? ` — ${note}` : "");
      return {
        content: [{ type: "text", text: msg }],
        details: { file, effectiveScope, note },
      };
    },
  });
}
