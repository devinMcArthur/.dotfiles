/**
 * edit-last-message.ts — Closes the Claude-Code-style "Esc to edit my last
 * message" ergonomic gap.
 *
 * Pi already supports the underlying functionality via `ctx.fork(entryId,
 * { position: "before" })` — it forks the session before a user message
 * AND auto-restores that prompt into the editor. This extension wraps the
 * "find last user message and fork" workflow behind a single command
 * (and shortcut) so editing a typoed or under-specified message is one
 * action, not three.
 *
 * Triggers:
 *   • `alt+e` — primary keybind ("e" for edit)
 *   • `/edit-last` — slash command, same effect
 *
 * Architecture note (important for future maintenance):
 *
 *   pi.registerShortcut handlers get ExtensionContext (no fork()), while
 *   pi.registerCommand handlers get ExtensionCommandContext (has fork()).
 *   To work around this, the alt+e shortcut calls
 *   pi.sendUserMessage("/edit-last") — input flows through pi's pipeline,
 *   matches the extension command FIRST (before agent processing), and
 *   routes to the /edit-last handler with the proper Command context.
 *
 *   Side effect: the abandoned session's chat history contains a final
 *   "/edit-last" user message before the fork. The new forked session
 *   starts clean (the fork happens BEFORE the user message we're editing,
 *   so /edit-last itself doesn't end up in the new branch). Acceptable.
 *
 * Behavior:
 *   1. Walk the current branch backward
 *   2. Find the most recent message entry with role === "user", skipping
 *      the synthetic "/edit-last" trigger if shortcut-sourced
 *   3. ctx.fork(entryId, { position: "before" }) — pi forks before that
 *      message AND restores its text into the editor for editing
 *
 * Edge cases:
 *   • Brand-new session, no user message → notify, no-op
 *   • Editor has unsaved typing → it will be clobbered by the restored
 *     prompt. Documented; live with it for v1.
 *
 * Auto-discovered from ~/.pi/agent/extensions/edit-last-message.ts.
 */
import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";

/**
 * Find the most recent user-role message entry on the current active
 * branch, skipping any whose text is the literal `/edit-last` trigger
 * (so the shortcut path doesn't try to fork-and-restore its own trigger).
 */
function findLastUserEntry(
  ctx: ExtensionCommandContext,
): { id: string; preview: string } | null {
  const branch = ctx.sessionManager.getBranch();
  for (let i = branch.length - 1; i >= 0; i--) {
    const entry: any = branch[i];
    if (entry?.type !== "message") continue;
    if (entry?.message?.role !== "user") continue;

    // Extract text content
    let text = "";
    const content = entry.message.content;
    if (typeof content === "string") {
      text = content;
    } else if (Array.isArray(content)) {
      for (const block of content) {
        if (block?.type === "text" && typeof block.text === "string") {
          text += block.text;
        }
      }
    }

    // Skip the /edit-last trigger itself if we land on it
    if (text.trim() === "/edit-last") continue;

    // Build a short preview
    let preview = text.trim().replace(/\s+/g, " ").slice(0, 60);
    if (text.length > 60) preview += "…";

    return { id: entry.id, preview };
  }
  return null;
}

async function editLastMessage(ctx: ExtensionCommandContext): Promise<void> {
  const found = findLastUserEntry(ctx);
  if (!found) {
    ctx.ui.notify(
      "edit-last: no previous user message in this session to edit.",
      "warning",
    );
    return;
  }

  // position: "before" creates a new session forked before this user
  // message, and pi auto-restores the message text into the editor.
  const result = await ctx.fork(found.id, { position: "before" });
  if (result?.cancelled) {
    ctx.ui.notify(
      "edit-last: fork was cancelled by another extension.",
      "warning",
    );
    return;
  }

  ctx.ui.notify(`edit-last: restored "${found.preview}"`, "info");
}

export default function (pi: ExtensionAPI) {
  // ---- Primary: /edit-last slash command (gets ExtensionCommandContext) ---
  pi.registerCommand("edit-last", {
    description:
      "Edit your most recent user message in place (forks before it; restores its text).",
    handler: async (_args, ctx) => {
      await editLastMessage(ctx);
    },
  });

  // ---- Keybind: alt+e — routes through input pipeline to /edit-last -------
  // The shortcut handler only receives ExtensionContext (no fork). We
  // dispatch via sendUserMessage which feeds pi's input pipeline; the
  // pipeline checks extension commands BEFORE any agent processing, so
  // "/edit-last" matches our registered command and runs with the proper
  // ExtensionCommandContext.
  pi.registerShortcut("alt+e", {
    description: "Edit your most recent message (rewinds session to it).",
    handler: async (_ctx) => {
      pi.sendUserMessage("/edit-last");
    },
  });
}
