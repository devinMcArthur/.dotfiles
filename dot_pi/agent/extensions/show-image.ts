/**
 * show-image.ts — Lets pi display images inline in the chat by emitting
 * an image-typed content block from a tool result. Pi's tool-execution
 * renderer handles Kitty/iTerm2/Ghostty graphics protocols, PNG
 * conversion, sizing, and fallback automatically (see
 * pi-coding-agent/dist/modes/interactive/components/tool-execution.js).
 *
 * Entry point: `show_image` tool — pi calls this when it wants to
 * display a screenshot, generated chart, fetched diagram, etc. Ask
 * pi (e.g. "show me ~/foo.png") and it will route to this tool.
 *
 * Path resolution: absolute paths used as-is; relative paths resolved
 * against ctx.cwd; `~` expanded to homedir.
 *
 * Supported formats: png, jpg/jpeg, gif, webp, bmp, svg (anything pi's
 * built-in conversion accepts; PNG is fast-path, others pass through
 * ImageMagick-ish conversion in pi).
 *
 * Auto-discovered from ~/.pi/agent/extensions/show-image.ts.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { homedir } from "node:os";
import { existsSync, readFileSync, statSync } from "node:fs";
import { resolve, extname, basename } from "node:path";

const MIME_BY_EXT: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
  ".bmp": "image/bmp",
  ".svg": "image/svg+xml",
};

// 10 MB cap on raw file size before base64 — keeps message payloads sane.
// Kitty graphics protocol can handle much more, but conversation log gets
// huge and providers don't appreciate it either.
const MAX_BYTES = 10 * 1024 * 1024;

function expandPath(p: string, cwd: string): string {
  let s = p.trim();
  if (s.startsWith("~/")) s = homedir() + s.slice(1);
  else if (s === "~") s = homedir();
  return resolve(cwd, s);
}

function mimeFor(path: string): string | null {
  return MIME_BY_EXT[extname(path).toLowerCase()] ?? null;
}

interface LoadResult {
  ok: true;
  base64: string;
  mimeType: string;
  bytes: number;
  filename: string;
}

interface LoadError {
  ok: false;
  error: string;
}

function loadImage(path: string): LoadResult | LoadError {
  if (!existsSync(path)) return { ok: false, error: `file not found: ${path}` };
  const st = statSync(path);
  if (!st.isFile()) return { ok: false, error: `not a regular file: ${path}` };
  if (st.size > MAX_BYTES)
    return {
      ok: false,
      error: `file too large: ${st.size} bytes (max ${MAX_BYTES})`,
    };
  const mimeType = mimeFor(path);
  if (!mimeType)
    return {
      ok: false,
      error: `unsupported extension: ${extname(path) || "(none)"} — supported: ${Object.keys(MIME_BY_EXT).join(", ")}`,
    };
  const buf = readFileSync(path);
  return {
    ok: true,
    base64: buf.toString("base64"),
    mimeType,
    bytes: st.size,
    filename: basename(path),
  };
}

export default function (pi: ExtensionAPI) {
  // ---- Tool: show_image (called by pi itself) ----------------------------
  pi.registerTool({
    name: "show_image",
    label: "Show image",
    description:
      "Display an image inline in the chat (Ghostty/Kitty/iTerm2/WezTerm). " +
      "Use to share screenshots, generated plots, fetched diagrams, or any " +
      "PNG/JPEG/GIF/WebP/BMP/SVG with the user. Path may be absolute, " +
      "relative to cwd, or use ~ for home.",
    promptSnippet:
      "show_image: render an image file inline in the chat for the user to see",
    promptGuidelines: [
      "Use show_image when describing visual content the user benefits from " +
        "seeing directly — screenshots you took, charts/plots you generated, " +
        "diagrams from docs, design mockups. Do not use for icons or trivial " +
        "decoration. Prefer show_image over a markdown ![]() link, which " +
        "won't render inline.",
    ],
    parameters: Type.Object({
      path: Type.String({
        description:
          "Path to the image file. Absolute, relative to cwd, or ~/...",
      }),
      caption: Type.Optional(
        Type.String({
          description:
            "Optional one-line caption shown alongside the image (for the " +
            "transcript / non-graphics terminals).",
        }),
      ),
    }),
    async execute(_id, params, _signal, _onUpdate, ctx) {
      const abs = expandPath(params.path, ctx.cwd);
      const r = loadImage(abs);
      if (!r.ok) {
        return {
          content: [{ type: "text", text: `show_image error: ${r.error}` }],
          details: { error: r.error, path: abs },
          isError: true,
        };
      }
      const label = params.caption
        ? `${r.filename} — ${params.caption}`
        : r.filename;
      return {
        content: [
          { type: "text", text: label },
          { type: "image", data: r.base64, mimeType: r.mimeType },
        ],
        details: {
          path: abs,
          mimeType: r.mimeType,
          bytes: r.bytes,
        },
      };
    },
  });
}
