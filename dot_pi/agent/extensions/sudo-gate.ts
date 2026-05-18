/**
 * sudo-gate.ts — Confirmation gate for privileged shell commands.
 *
 * Paired with /etc/sudoers.d/pi-agent, which lets pi run a small allowlist of
 * binaries (pacman, yay, chsh, hostnamectl) without a password. This extension
 * adds the human-in-the-loop: every time pi tries to run a privileged command
 * via the `bash` tool, you get a confirmation popup showing the exact command.
 *
 * Without explicit approval, the call is blocked.
 *
 * Also installs a compact custom footer with a shield glyph on the right
 * (nf-md-shield_check, requires a Nerd Font) instead of an extra status row.
 *
 * Auto-discovered by pi from ~/.pi/agent/extensions/sudo-gate.ts.
 */
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { basename, relative } from "node:path";
import { homedir } from "node:os";

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

function tildify(cwd: string): string {
  const home = homedir();
  if (cwd === home) return "~";
  if (cwd.startsWith(home + "/")) return "~/" + relative(home, cwd);
  return cwd;
}

export default function (pi: ExtensionAPI) {
  // --- Gate -----------------------------------------------------------------
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command ?? "";
    const matched = detect(command);
    if (!matched) return;

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
  });

  // --- Custom footer --------------------------------------------------------
  // Mirrors pi's default footer (tokens on left; model + cwd + branch on right)
  // and adds a single shield glyph at the far right to indicate the gate is
  // active. Avoids the extra status row produced by `ctx.ui.setStatus`.
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());
      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // Token usage from session
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
