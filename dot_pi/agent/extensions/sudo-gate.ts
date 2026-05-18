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
 * Auto-discovered by pi from ~/.pi/agent/extensions/sudo-gate.ts.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

/**
 * Commands that we want to gate. Matches the binary at a word boundary so
 * incidental occurrences in strings (e.g. `echo "no sudo"`) don't trip the
 * gate. `yay` is included because it internally escalates to sudo.
 */
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

export default function (pi: ExtensionAPI) {
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

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setStatus("sudo-gate", "sudo-gate active");
  });
}
