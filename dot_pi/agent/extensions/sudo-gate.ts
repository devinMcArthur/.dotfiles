/**
 * sudo-gate.ts — Two-tier confirmation gate for privileged commands.
 *
 * Tier 1: if the target binary is in your NOPASSWD sudoers allowlist
 *         (parsed from `sudo -ln`), pop a simple Allow/Deny confirm.
 * Tier 2: otherwise, pop a `wofi --password` dialog so you can type the
 *         password. The password is piped into sudo via an askpass
 *         script (mode 0700, in a one-shot mkdtemp dir) — it never
 *         appears in the command string, session log, or pi-memory.
 *
 * Also installs a compact custom footer with a shield-check glyph in
 * place of the default "extension status" row.
 *
 * Auto-discovered by pi from ~/.pi/agent/extensions/sudo-gate.ts.
 */
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import {
  spawnSync,
  execFileSync,
  type SpawnSyncReturns,
} from "node:child_process";
import {
  mkdtempSync,
  writeFileSync,
  unlinkSync,
  rmdirSync,
  chmodSync,
} from "node:fs";
import { tmpdir, homedir } from "node:os";
import { dirname, join, relative } from "node:path";

// --------------------------------------------------------------------------
// Detection
// --------------------------------------------------------------------------

const PRIVILEGED = [
  { name: "sudo", re: /(^|[\s;&|])sudo(\s|$)/ },
  { name: "yay", re: /(^|[\s;&|])yay(\s|$)/ },
];

function detect(command: string): string | null {
  for (const { name, re } of PRIVILEGED) {
    if (re.test(command)) return name;
  }
  return null;
}

/** Take the binary `sudo` is escalating to. Resolves to absolute path. */
function extractSudoBinary(command: string): string | null {
  const m = command.match(/\bsudo\b((?:\s+-\S+)*)\s+(\S+)/);
  if (!m) return null;
  let bin = m[2];
  if (bin.startsWith("-") || bin === "") return null;
  if (!bin.startsWith("/")) {
    try {
      bin = execFileSync("/usr/bin/env", ["which", bin], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      }).trim();
    } catch {
      return null;
    }
  }
  return bin;
}

/** Parse `sudo -ln` once to learn this user's NOPASSWD binary allowlist. */
let nopasswdBins: Set<string> | null = null;
function loadNopasswd(): Set<string> {
  if (nopasswdBins) return nopasswdBins;
  const set = new Set<string>();
  try {
    const out = execFileSync("/usr/bin/sudo", ["-ln"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    for (const line of out.split("\n")) {
      const m = line.match(/NOPASSWD:\s*(.+?)(?:\s*#|$)/);
      if (!m) continue;
      for (const part of m[1].split(",")) {
        const bin = part.trim().split(/\s+/)[0];
        if (bin) set.add(bin);
      }
    }
  } catch {
    /* sudo -ln itself prompted; treat allowlist as empty */
  }
  nopasswdBins = set;
  return set;
}

function needsPassword(command: string, matched: string): boolean {
  const allow = loadNopasswd();
  if (matched === "yay") return !allow.has("/usr/bin/yay");
  const bin = extractSudoBinary(command);
  return bin ? !allow.has(bin) : true;
}

// --------------------------------------------------------------------------
// Askpass plumbing
// --------------------------------------------------------------------------

/** Tracks every askpass dir we've created so tool_execution_end can clean up. */
const pendingAskpass = new Map<string, string>(); // toolCallId -> dir

function shEscape(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`;
}

function makeAskpass(password: string): { dir: string; script: string } {
  const dir = mkdtempSync(join(tmpdir(), "pi-askpass-"));
  const script = join(dir, "askpass.sh");
  writeFileSync(
    script,
    `#!/bin/sh\nprintf '%s\\n' ${shEscape(password)}\n`,
    { mode: 0o700 },
  );
  chmodSync(script, 0o700);
  chmodSync(dir, 0o700);
  return { dir, script };
}

function cleanupAskpass(dir: string | undefined) {
  if (!dir) return;
  try {
    unlinkSync(join(dir, "askpass.sh"));
  } catch {}
  try {
    rmdirSync(dir);
  } catch {}
}

/**
 * Prompt for a password. Tries dialog backends in order of UX quality:
 *   1. zenity --password           (GTK dialog, masked, Wayland-native)
 *   2. systemd-ask-password        (system PAM agent / TTY fallback)
 * Returns undefined on cancel / no backend.
 *
 * (We don't use wofi here because `wofi --dmenu --password` requires
 * picking from a list to submit, which fails for free-form input.)
 */
function promptPassword(promptText: string): string | undefined {
  const backends: Array<{ cmd: string; args: string[] }> = [
    {
      cmd: "zenity",
      args: [
        "--password",
        "--title",
        "pi sudo-gate",
        "--text",
        promptText,
      ],
    },
    { cmd: "systemd-ask-password", args: ["--no-tty", promptText] },
  ];
  for (const { cmd, args } of backends) {
    let r: SpawnSyncReturns<string>;
    try {
      r = spawnSync(cmd, args, {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      });
    } catch {
      continue; // not installed; try next
    }
    if (r.error || r.status === null) continue;
    if (r.status !== 0) return undefined; // user cancelled
    const pw = (r.stdout ?? "").replace(/\r?\n$/, "");
    return pw === "" ? undefined : pw;
  }
  return undefined;
}

/** Rewrite the command so each `sudo` *command position* becomes `sudo -A`
 *  and SUDO_ASKPASS is exported up front.
 *
 *  Carefully avoids replacing `sudo` inside filenames or arguments like
 *  `/etc/pam.d/sudo`. Only matches when preceded by start-of-string or a
 *  shell separator (whitespace, `;`, `&&`, `||`, `|`).
 */
function rewriteWithAskpass(command: string, askpassPath: string): string {
  const rewritten = command.replace(
    /(^|[\s;|&])sudo\b(?!\s+-A\b)/g,
    "$1sudo -A",
  );
  return `SUDO_ASKPASS=${shEscape(askpassPath)} ${rewritten}`;
}

// --------------------------------------------------------------------------
// Footer (unchanged from previous version)
// --------------------------------------------------------------------------

function tildify(cwd: string): string {
  const home = homedir();
  if (cwd === home) return "~";
  if (cwd.startsWith(home + "/")) return "~/" + relative(home, cwd);
  return cwd;
}

// --------------------------------------------------------------------------
// Extension entry
// --------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // ---- Gate ---------------------------------------------------------------
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command ?? "";
    const matched = detect(command);
    if (!matched) return;

    if (!needsPassword(command, matched)) {
      // Tier 1: simple confirm — already NOPASSWD.
      const ok = await ctx.ui.confirm(
        `Privileged command (${matched})`,
        `Allow this to run with elevated privileges?\n\n${command}`,
      );
      if (!ok) {
        return {
          block: true,
          reason: `User denied privileged command (${matched}).`,
        };
      }
      return;
    }

    // Tier 2: password required.
    const password = promptPassword(`sudo password (${matched}):`);
    if (!password) {
      return {
        block: true,
        reason: `Password prompt cancelled for ${matched}.`,
      };
    }
    const { dir, script } = makeAskpass(password);
    pendingAskpass.set(event.toolCallId, dir);

    // Mutate the command so sudo reads the password from the askpass script.
    event.input.command = rewriteWithAskpass(command, script);
  });

  // Always clean up the askpass directory after the tool finishes.
  pi.on("tool_execution_end", async (event) => {
    const dir = pendingAskpass.get(event.toolCallId);
    if (!dir) return;
    pendingAskpass.delete(event.toolCallId);
    cleanupAskpass(dir);
  });

  // Sweep any stragglers on shutdown (e.g., crash mid-exec).
  pi.on("session_shutdown", async () => {
    for (const [id, dir] of pendingAskpass) {
      cleanupAskpass(dir);
      pendingAskpass.delete(id);
    }
  });

  // ---- Custom footer ------------------------------------------------------
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());
      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          let input = 0,
            output = 0,
            cost = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              const m = e.message as AssistantMessage;
              input += m.usage.input;
              output += m.usage.output;
              cost += m.usage.cost.total;
            }
          }
          const fmt = (n: number) =>
            n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;

          const left = theme.fg(
            "dim",
            `↑${fmt(input)} ↓${fmt(output)} $${cost.toFixed(3)}`,
          );

          const cwd = tildify(ctx.cwd);
          const branch = footerData.getGitBranch();
          const model = ctx.model?.id ?? "no-model";
          const shield = theme.fg("accent", "\u{F0565}"); // nf-md-shield_check

          const rightParts = [
            theme.fg("dim", model),
            theme.fg("dim", cwd),
            branch ? theme.fg("dim", `(${branch})`) : null,
            shield,
          ].filter(Boolean) as string[];
          const right = rightParts.join(theme.fg("muted", " · "));

          const padLen = Math.max(
            1,
            width - visibleWidth(left) - visibleWidth(right),
          );
          return [truncateToWidth(left + " ".repeat(padLen) + right, width)];
        },
      };
    });
  });
}
